# ============================================================================
package Mac::iPhoto::Exif::Commandline;
# ============================================================================

use 5.010;
use utf8;
no if $] >= 5.017004, warnings => qw(experimental::smartmatch);

use Moose;
with qw(MooseX::Getopt);
extends qw(Mac::iPhoto::Exif);

use Moose::Util::TypeConstraints;
use Term::ANSIColor;
use Scalar::Util qw(weaken);

has 'force' => (
    is                  => 'ro',
    isa                 => 'Bool',
    default             => 0,
    documentation       => 'Do not confirm action [Default: false]',
);

has 'loglevel' => (
    is                  => 'ro',
    isa                 => enum(\@Mac::iPhoto::Exif::LEVELS),
    default             => 'info',
    documentation       => 'Log level [Values: '.join(',',@Mac::iPhoto::Exif::LEVELS).'; Default: info]',
);

MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 
    'Mac::iPhoto::Exif::Type::File'             => '=s',
);
MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 
    'Mac::iPhoto::Exif::Type::Dirs'             => '=s@',
);


after 'log' => sub {
    my ($self,$loglevel,$message,@params) = @_;
    
    my $logmessage = sprintf( $message, map { $_ // '000000' } @params );
    
    my ($level_pos) = grep { $Mac::iPhoto::Exif::LEVELS[$_] eq $loglevel } 0 .. $#Mac::iPhoto::Exif::LEVELS;
    my ($level_max) = grep { $Mac::iPhoto::Exif::LEVELS[$_] eq $self->loglevel } 0 .. $#Mac::iPhoto::Exif::LEVELS;
    
    if ($level_pos >= $level_max) {
        given ($loglevel) {
            when ('error') {
                print color 'bold red';
            }
            when ('warn') {
                print color 'bold bright_yellow';
            }
            when ('info') {
                print color 'bold cyan';
            }
            when ('debug') {
                print color 'bold white';
            }
        }
        printf "%5s: ",$loglevel;
        print color 'reset';
        say $logmessage;
    }
};

around 'run' => sub {
    my $orig = shift;
    my $self = shift;
    
    my $self_copy = $self;
    weaken($self_copy);
    local $SIG{__WARN__} = sub {
        my ($message) = shift;
        chomp $message;
        $self_copy->log('warn',$message);
    };
    
    binmode STDOUT, ":utf8";
    
    unless ($self->backup || $self->force || $self->dryrun) {
        $self->log('warn','Your pictures will be altered without backup. Type "yes" if you want to continue!');
        my $confirm = <STDIN>;
        chomp($confirm);
        exit()
            unless $confirm =~ m/^\s*yes\s*$/i;
    }
    
    $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

