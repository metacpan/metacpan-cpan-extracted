package App::Foo;

use v5.14;
use warnings;
use Data::Dumper;

use Getopt::EX::Hashed;

# DEFAULT: is => 'ro' / 'rw'
if (our $ACCESSOR_DEFAULT_RO) {
    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);
}
if (our $ACCESSOR_DEFAULT_RW) {
    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'rw' ]);
}
if (our $ACCESSOR_DEFAULT_ERROR1) {
    Getopt::EX::Hashed->configure(DEFAULT => 'rw' );
}
if (our $ACCESSOR_DEFAULT_ERROR2) {
    Getopt::EX::Hashed->configure(DEFAULT => [ 'rw' ]);
}

if (defined our $REPLACE_UNDERSCORE) {
    Getopt::EX::Hashed->configure(REPLACE_UNDERSCORE => $REPLACE_UNDERSCORE);
}
if (defined our $REMOVE_UNDERSCORE) {
    Getopt::EX::Hashed->configure(REMOVE_UNDERSCORE => $REMOVE_UNDERSCORE);
}

has string   => ( spec => '=s' );
has say      => ( spec => '=s', default => "Hello" );
has number   => ( spec => '=i' );
has implicit => ( spec => ':42' );
has start    => ( spec => '=i s begin' );
has finish   => ( spec => '=i f end' );
has tricia   => ( spec => 'trillian=s' );
has zaphord  => ( spec => '', alias => 'beeblebrox' );
has so_long  => ( spec => '' );
has list     => ( spec => '=s@' );
has hash     => ( spec => '=s%' );

# imcremental coderef
has [ qw( left right both ) ] => ( spec => '=i' );
has '+both' => default => sub {
    $_->{left} = $_->{right} = $_[1];
};

# action
has android => ;
has paranoid => spec => '=s',
		action => sub { $_->{android} = $_[1] };

# is => 'ro'
if (our $ACCESSOR_RO) {
    has [ qw(
	+string +say +number +implicit +start +finish +tricia +zaphord +so_long +list +hash 
	+left +right +both
	+android +paranoid
    ) ] => is => 'ro' ;
}

# erroneous incremental usage: live or die?
if (our $WRONG_INCREMENTAL) {
    has '+no_no_no' => default => 1;
}

# default/action co-exist
if (our $DEFAULT_AND_ACTION) {
    has [ 'restaurant', 'shop' ] =>
	spec => '=s',
	default => "Pizza Hat",
	action  => sub {
	    my($name, $s) = @_;
	    $_->{$name} = "$s at the end of universe.";
       	};
}

if (our $TAKE_IT_ALL) {
    has ARGV => default => [];
    has '<>' => default => sub {
	push @{$_->{ARGV}}, $_[0];
    };
}

no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = @_;
    use Getopt::Long;
    $app->getopt or die;
    return @ARGV;
}

1;

package App::Bar;

use v5.14;
use warnings;
use Data::Dumper;

use Getopt::EX::Hashed;

has string   => ( spec => '=s' );
has say      => ( spec => '=s', default => "Hello" );
has number   => ( spec => '=i' );
has implicit => ( spec => ':42' );
has start    => ( spec => '=i s begin' );
has finish   => ( spec => '=i f end' );
has tricia   => ( spec => 'trillian=s' );
has zaphord  => ( spec => '', alias => 'beeblebrox' );
has so_long  => ( spec => '' );
has list     => ( spec => '=s@' );
has hash     => ( spec => '=s%' );

no Getopt::EX::Hashed;

sub run {
    my $app = shift;
    local @ARGV = @_;
    use Getopt::Long;
    $app->getopt or die;
    return @ARGV;
}

1;
