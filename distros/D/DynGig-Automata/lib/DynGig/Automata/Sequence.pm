=head1 NAME

DynGig::Automata::Sequence - Sequential automation framework.

=cut
package DynGig::Automata::Sequence;

use warnings;
use strict;
use Carp;

use YAML::XS;
use File::Spec;

use DynGig::Automata::Serial;
use DynGig::Automata::Thread;

our $THREAD = 0;

=head1 SYNOPOSIS

 use DynGig::Automata::Sequence;

 $DynGig::Automata::Sequence::THREAD = $thread_count;  ## select thread mode

 my $sequence = DynGig::Automata::Sequence->new( 'blah' );

 $sequence->run  ## see DynGig::Util::Logger for parameter
 (
     log => '/home/bob/log/blah',
     time => 'local',
     context => \%context,
     thread => $thread_count,
 );

=head1 DESCRIPTION

Execution pauses when an error is encountered in any job.
Execution resumes when all errors are removed from the alert database.

Execution pauses when B<pause> is active.
Execution resumes when B<pause> is remove.

Execution terminates when I<stop> is active.

=head1 CONFIGURATION FILE

A YAML file 'B<conf>' is expected under the application root directory.
It should load into a HASH with the following fields.

 KEY               TYPE             NOTE
 ===               ====             ====
 target            HASH
 queue             AoH
 begin             HASH             optional
 end               HASH             optional

Each sub-HASH represents a code/param HASH, where I<code> is the path to
the plugin subroutine, and I<param> is a HASH for the parameter of I<code>.
( see B<PLUGIN API> )

=head1 PLUGIN API

Each plugin is a file that contains a subroutine. The path of the file
corresponds to I<code> in the configuration file. e.g.

 return sub
 {
     my %param = @_;
     my $logger = $param{logger};    ## CODE
     my $target = $param{target};
     my $context = $param{context};
     ## additional param are passed from the configuration file

     &$logger( "blah" );
     &$logger( "%s", 'blah' );
     ...
 };

=head1 MODE

In I<serial> mode, I<target> code must have an exhaustive batching behavior.
e.g.  n targets T1 .. Tn into k batches in k iterations of I<target> code

  ITERATION        TARGET
  =========        ======
  1                T1, T2 .. Tm
  2                Tm+1 ..
  ...
  k                .. Tn-1, Tn
  k+1              undef

In I<serial> mode, the I<target> parameter for plugin is ARRAY.
Whereas in I<thread> mode, scalar.

=head1 ARTIFACT

The following directories or symlinks to which, if not already exist
are created under the application root directory.

 DIRECTORY         NOTE
 =========         ====
 run               where alert database and symlink to log are kept
 param             where override parameter files are kept

The following files are created.

 FILE              NOTE
 ====              ====
 run/$name.alert   alert database
 run/$name.log     symlink to the log file

The following file is used to control execution

 FILE              NOTE
 ====              ====
 run/$name.pause   lock file for pause/stop

=cut
sub new
{
    my ( $class, $name ) = @_;

    croak 'undefined/invalid name' if ! defined $name || ref $name;

    my $param = YAML::XS::LoadFile( File::Spec->join( 'conf', $name ) );

    croak 'invalid config' unless $param && ref $param eq 'HASH';

    my $queue = $param->{queue} ||= [];

    croak 'invalid queue config' if ref $queue ne 'ARRAY';
##  load code
    my @global = grep { $param->{$_} } qw( target begin end );

    for my $plugin ( @$queue, map { $param->{$_} } @global )
    {
        my $error = 'invalid plugin ' . YAML::XS::Dump $plugin;

        croak $error . ( $@ || '' ) if ref $plugin ne 'HASH'
            || ref ( $plugin->{param} ||= {} ) ne 'HASH'
            || ref ( $plugin->{code} = do $plugin->{code} ) ne 'CODE';

        map { $plugin->{$_} ||= 0 } qw( redo retry timeout );
    }

    map { $param->{$_}{name} = $_ } @global;
##  check job names for collision
    for ( my %name, my $i = 0; $i < @$queue; $i ++ )
    {
        my $name = defined $queue->[$i]{name} ? $queue->[$i]{name} : $i + 1;
        my $j = $name{$name};

        croak sprintf "name '%s' collided in job %d and %d\n",
            $name, $j + 1, $i + 1 if defined $j;

        $queue->[ $name{$name} = $i ]{name} = "job.$name";
    }

    $param->{name} = $name;

    bless +
    {
        sequence => $THREAD
        ? DynGig::Automata::Thread->new( %$param ) 
        : DynGig::Automata::Serial->new( %$param )
    };
}

sub AUTOLOAD
{
    my $this = shift @_;

    return our $AUTOLOAD =~ /::(setup|file)$/
        ? $this->{sequence}->$1( @_ ) : undef;
}

=head1 NOTE

See DynGig::Automata

=cut

1;

__END__
