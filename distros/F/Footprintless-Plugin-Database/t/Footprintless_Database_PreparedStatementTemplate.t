use strict;
use warnings;

use Data::Dumper;
use lib 't/lib';
use Test::More tests => 12;
use File::Basename;
use File::Spec;
use Footprintless;
use Footprintless::Util qw(
    dumper
    factory
    slurp
    spurt
    temp_dir
);

BEGIN {

    package Context;

    sub new {
        my $self = bless( {}, shift );
        $self->_init(@_);
    }

    sub _init {
        my ( $self, %props ) = @_;
        foreach my $key ( grep { substr( $_, 0, 1 ) ne '_' } keys(%props) ) {
            $self->{$key} = $props{$key};
        }
        $self->{_properties} = {
            map { substr( $_, 1 ) => $props{$_} }
            grep { substr( $_, 0, 1 ) eq '_' } keys(%props)
        };
        return $self;
    }

    sub AUTOLOAD {
        my ( $self, $new_value ) = @_;
        my ($key) = $Context::AUTOLOAD =~ /^.*::(.*?)$/;
        my $value = defined($new_value)
            ? $self->{_properties}->{$key} = $new_value
            : $self->{_properties}->{$key};
        die("Undefined property [$key]") unless defined($value);
        return $value;
    }
}

BEGIN { use_ok('Footprintless::Plugin::Database::PreparedStatementTemplate') }

eval {
    require Getopt::Long;
    Getopt::Long::Configure( 'pass_through', 'bundling' );
    my $level = 'error';
    Getopt::Long::GetOptions( 'log:s' => \$level );

    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout',
        log_level => Log::Any::Adapter::Util::numeric_level($level) );
};

my $logger = Log::Any->get_logger();

# Test the template implementation of key
{
    my $context = Context->new(
        _fruit => 'apple',
        _color => 'green',
        music  => 'classical',
        sport  => 'soccer'
    );
    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'ONE *A* TWO *B* THREE *A* FOUR *B* FIVE *C* SIX *D* SEVEN',
        '*A*' => 'fruit',
        '*B*' => 'music',
        '*C*' => { key => 'color' },
        '*D*' => { key => 'sport' }
    );
    is_deeply(
        $statement->query($context),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE ? SIX ? SEVEN',
            parameters => [ 'apple', 'classical', 'apple', 'classical', 'green', 'soccer' ]
        },
        'key 1'
    );
    $context->fruit('durian');
    $context->color('neon green');
    $context->{music} = 'ska';
    $context->{sport} = 'base jumping';
    is_deeply(
        $statement->query($context),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE ? SIX ? SEVEN',
            parameters => [ 'durian', 'ska', 'durian', 'ska', 'neon green', 'base jumping' ]
        },
        'key 2'
    );
}

# Test the template implementation of references
{
    my $value1    = "Hippo";
    my $value2    = "Rhino";
    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'ONE *A* TWO *B* THREE *A* FOUR *B* FIVE',
        '*A*' => \$value1,
        '*B*' => { reference => \$value2 }
    );
    is_deeply(
        $statement->query(),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE',
            parameters => [ 'Hippo', 'Rhino', 'Hippo', 'Rhino' ]
        },
        'references 1'
    );
    $value1 = "Cat";
    $value2 = "Dog";
    is_deeply(
        $statement->query(),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE',
            parameters => [ 'Cat', 'Dog', 'Cat', 'Dog' ]
        },
        'references 2'
    );
}

# Test the template implementation of code
{
    my $count = 1;

    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'ONE *A* TWO *B* THREE *A* FOUR *B* FIVE *C* SIX *D* SEVEN',
        '*A*' => sub {"fruit $count"},
        '*B*' => sub {"music $count"},
        '*C*' => {
            code => sub {"color $count"}
        },
        '*D*' => {
            code => sub {"sport $count"}
        }
    );
    is_deeply(
        $statement->query(),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE ? SIX ? SEVEN',
            parameters => [ 'fruit 1', 'music 1', 'fruit 1', 'music 1', 'color 1', 'sport 1' ]
        },
        'code 1'
    );
    $count = 2;
    is_deeply(
        $statement->query(),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE ? SIX ? SEVEN',
            parameters => [ 'fruit 2', 'music 2', 'fruit 2', 'music 2', 'color 2', 'sport 2' ]
        },
        'code 2'
    );
}

# Test the template implementation of value
{
    my $fruit = "fruit 1";
    my $music = "music 1";

    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'ONE *A* TWO *B* THREE *A* FOUR *B* FIVE',
        '*A*' => { value => $fruit },
        '*B*' => { value => $music }
    );
    is_deeply(
        $statement->query(),
        {   sql        => 'ONE ? TWO ? THREE ? FOUR ? FIVE',
            parameters => [ 'fruit 1', 'music 1', 'fruit 1', 'music 1' ]
        },
        'value 1'
    );
    $fruit = "fruit 2";
    $music = "music 2";
    is_deeply(
        $statement->query(),
        {   sql => 'ONE ? TWO ? THREE ? FOUR ? FIVE',

            # no change
            parameters => [ 'fruit 1', 'music 1', 'fruit 1', 'music 1' ]
        },
        'value 2'
    );
}

# Test dangerous naming
{
    my $count   = 1;
    my $context = Context->new(
        _color => 'green',
        music  => 'classical',
    );

    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'XXXXX ONE X TWO XX THREE X FOUR XX FIVE XXX SICKS XXXX SEVEN XXXXX',
        X     => sub     {"fruit $count"},
        XX    => \$count,
        XXX   => 'music',
        XXXX  => 'color',
        XXXXX => { value => 'pig' }
    );

    is_deeply(
        $statement->query($context),
        {   sql        => '? ONE ? TWO ? THREE ? FOUR ? FIVE ? SICKS ? SEVEN ?',
            parameters => [ 'pig', 'fruit 1', '1', 'fruit 1', '1', 'classical', 'green', 'pig' ]
        },
        'dangerous naming 1'
    );
    $count = 2;
    $context->{music} = 'ska';
    $context->color('neon green');
    is_deeply(
        $statement->query($context),
        {   sql        => '? ONE ? TWO ? THREE ? FOUR ? FIVE ? SICKS ? SEVEN ?',
            parameters => [ 'pig', 'fruit 2', '2', 'fruit 2', '2', 'ska', 'neon green', 'pig' ]
        },
        'dangerous naming 2'
    );

    $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        'XXX ONE XXX TWO XXX',
        X  => { value => 'AAA' },
        XX => { value => 'BBB' }
    );
    is_deeply(
        $statement->query($context),
        {   sql        => '?? ONE ?? TWO ??',
            parameters => [ 'BBB', 'AAA', 'BBB', 'AAA', 'BBB', 'AAA' ]
        },
        'dangerous naming 3'
    );

}
