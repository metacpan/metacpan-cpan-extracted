#******************************************************************************
#*
#*                             GELLYFISH SOFTWARE
#*
#*
#******************************************************************************
#*
#*          PROGRAM      :   Linux::Cpuinfo
#*
#*          AUTHOR       :   JNS
#*
#*          DESCRIPTION  :   Object Oriented interface to /proc/cpuinfo
#*
#*****************************************************************************

package Linux::Cpuinfo;

=head1 NAME

Linux::Cpuinfo - Object Oriented Interface to /proc/cpuinfo

=head1 SYNOPSIS

  # Old interface ( for single processor devices )

  use Linux::Cpuinfo;

  my $cpu = Linux::Cpuinfo->new();

  die ('Could not find cpu info (does /proc/cpuinfo exists?)')
    unless ref $cpu;

  print $cpu->model_name();


  # New Interface ( copes with SMP ).

  my $cpuinfo = Linux::Cpuinfo->new();

  $cnt  = $cpuinfo->num_cpus();	 # > 1 for an SMP system


   foreach my $cpu ( $cpuinfo->cpus() )
   {
     print $cpu->bogomips(),"\n";
   }

=head1 DESCRIPTION

On Linux systems various information about the CPU ( or CPUs ) in the
computer can be gleaned from C</proc/cpuinfo>. This module provides an
object oriented interface to that information for relatively simple use
in Perl programs.

=head2 METHODS

The interface has changed between revisions 1.2 and 1.3 of this module
in order to deal with systems with multiple CPUs - now the details of a
CPU are acquired by the methods of the Linux::Cpuinfo::Cpu objects returned
by the C<cpu()> and C<cpus()> methods of this class. However in order to
retain backward compatibility if the methods described for Linux::Cpuinfo::Cpu
are called a Linux::Cpuinfo object then it will work as previously - returning
the details of the sole CPU on a single processor system and the last discovered
 CPU on system with multiple processors ( this was the implicit behaviour on
previous versions).  Whilst not strictly deprecated this interface is not
the recommended one.

=over 4

=cut

use 5.006;

use strict;
use warnings;

use Carp;


our $AUTOLOAD;

our  $VERSION = '1.12';

$VERSION = eval $VERSION;

=item cpuinfo

Returns a blessed object suitable for calling the rest of the methods on or
a false value if for some reason C</proc/cpuinfo> cant be opened.  The first
argument can be an alternative file that provides identical information.  You
may also supply a hashref containing other arguments - the valid keys are

=over 2

=item NoFatal

The default behaviour is for the method to croak if an attribute is requested
that is not available on this particular CPU.  If this argument is supplied
with a true value then the method will return undef instead.  

=back

=cut

sub cpuinfo
{
    my ( $proto, $file, $args ) = @_;

    my $class = ref($proto) || $proto;

    my $self;

    if ( $file and ref($file) and ref($file) eq 'HASH' )
    {
        $args = $file;
        $file = undef;
    }

    $file ||= '/proc/cpuinfo';

    if ( -e $file and -f $file )
    {

        if ( open( CPUINFO, $file ) )
        {
            $self = {};

            local $/ = '';

            $self->{_private}->{num_cpus} = 0;

            $self->{_cpuinfo} = [];

            while (<CPUINFO>)
            {
                chomp;


                my $cpuinfo = {};

                foreach my $cpuline ( split /\n/ )
                {
                    my ( $attribute, $value ) = split /\s*:\s*/, $cpuline;

                    $attribute =~ s/\s+/_/;
                    $attribute = lc($attribute);

                    if ( $value && $value =~ /^(no|not available|yes)$/ )
                    {
                        $value = $value eq 'yes' ? 1 : 0;
                    }

                    if ( $attribute eq 'flags' )
                    {
                        @{ $cpuinfo->{flags} } = split / /, $value;
                    }
                    else
                    {
                        $cpuinfo->{$attribute} = $value;
                    }

                }
                # This is a lot uglier than it needs to be. The perl 6
                # version is 6 lines.
                # It seems that single core arm6 or 7 cores highlight
                # a bug where there is a spurious \n in there
                # The alert will correctly surmise this breaks for assymetric 
                # cpus
                
                my $ok_to_add = 1;
                if ( @{ $self->{_cpuinfo} } )
                {
                   if (keys %{$self->{_cpuinfo}->[-1]->{_data}} != keys %{$cpuinfo} )
                   {
                      foreach my $key ( keys %{$cpuinfo} )
                      {
                         $self->{_cpuinfo}->[-1]->{_data}->{$key} = $cpuinfo->{$key};
                      }
                      $ok_to_add = 0;
                   }
                }
                if ( $ok_to_add )
                {
                   my $cpuinfo_cpu = Linux::Cpuinfo::Cpu->new( $cpuinfo, $args );
                   $self->{_private}->{num_cpus}++;
                   push @{ $self->{_cpuinfo} }, $cpuinfo_cpu;
                }
            }

            bless $self, $class;
            close CPUINFO;    # can this fail
        }
    }

    return $self;
}

# just in case anyone is a lame as me :)

*new = \&cpuinfo;

=item num_cpus

Returns the number of CPUs reported for this system.  

=cut

sub num_cpus
{
    my ($self) = @_;

    return $self->{_private}->{num_cpus};
}

=item cpu SCALAR $cpu

Returns an object of type Linux::Cpuinfo::Cpu corresponding to the CPU of
index $cpu ( where $cpu >= 0 and $cpu < num_cpus() ) - if $cpu is omitted
this will return an object correspnding to the last CPU found.

If $cpu is out of bounds with respect to the number of CPUs then it will
be set to the first or last CPU ( depending whether $cpu was < 0 or >num_cpus )

=cut

sub cpu
{
    my ( $self, $cpu ) = @_;

    if ( defined $cpu )
    {
        $cpu = 0 if ( $cpu < 0 );
        $cpu = $#{ $self->{_cpuinfo} } if $cpu > $#{ $self->{_cpuinfo} };
    }
    else
    {
        $cpu = $#{ $self->{_cpuinfo} };
    }

    return $self->{_cpuinfo}->[$cpu];
}

=item cpus

Returns a list containing objects of type Linux::Cpuinfo::Cpu corresponding 
to the CPUs discovered in this system.   If the method is called in a scalar
context it will return a reference to an array of those objects.

=cut

sub cpus
{
    my ($self) = @_;

    if ( wantarray() )
    {
        return @{ $self->{_cpuinfo} };
    }
    else
    {
        return $self->{_cpuinfo};
    }
}

sub AUTOLOAD
{

    my ($self) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my ($method) = $AUTOLOAD =~ /.*::(.+?)$/;

    {
        no strict 'refs';

        *{$AUTOLOAD} = sub {
            my ($self) = @_;
            return $self->{_cpuinfo}->[ $#{ $self->{_cpuinfo} } ]->$method();
        };
    }
    goto &{$AUTOLOAD};
}

# The following are autoloaded methods of the Linux::Cpuinfo::Cpu class

=back

=head2 PER CPU METHODS OF Linux::Cpuinfo::Cpu

Note that not all of the methods listed here are available on all CPU
types.  For instance, MIPS CPUs have no cpuid instruction, but might
sport a byte order attribute.

There are also some other methods available for some CPUs which aren't
listed here.

=over 4

=item processor	

This is the index of the processor this information is for, it will be zero
for a the first CPU (which is the only one on single-proccessor systems), one
for the second and so on.

=item vendor_id	

This is a vendor defined string for X86 CPUs such as 'GenuineIntel' or
'AuthenticAMD'. 12 bytes long, since it is returned via three 32 byte long
registers.

=item cpu_family	

This should return an integer that will indicate the 'family' of the 
processor - This is for instance '6' for a Pentium III. Might be undefined for
non-X86 CPUs.

=item model or cpu_model

An integer that is probably vendor dependent that indicates their version 
of the above cpu_family

=item model_name	

A string such as 'Pentium III (Coppermine)'.

=item stepping	

I'm lead to believe this is a version increment used by intel.

=item cpu_mhz

I guess this is self explanatory - it might however be different to what
it says on the box. The Mhz is measured at boot time by the kernel and
represents the true Mhz at that time.

=item bus_mhz

The MHz of the bus system.

=item cache_size	

The cache size for this processor - it might well have the units appended
( such as 'KB' )

=item fdiv_bug	

True if this bug is present in the processor.

=item hlt_bug		

True if this bug is present in the processor.

=item sep_bug		

True if this bug is present in the processor.

=item f00f_bug	

True if this bug is present in the processor.

=item coma_bug	

True if this bug is present in the processor.

=item fpu		

True if the CPU has a floating point unit.

=item fpu_exception	

True if the floating point unit can throw an exception.

=item cpuid_level

The C<cpuid> assembler instruction is only present on X86 CPUs. This attribute
represents the level of the instruction that is supported by the CPU. The first
CPUs had only level 1, newer chips have more levels and can thus return more
information.

=item wp

No idea what this is on X86 CPUs.

=item flags

This is the set of flags that the CPU supports - this is returned as an
array reference.

=item byte_order

The byte order of the CPU, might be little endian or big endian, or undefined
for unknown.

=item bogomips	

A system constant calculated when the kernel is booted - it is a (rather poor)
measure of the CPU's performance.

=back

=cut

package Linux::Cpuinfo::Cpu;

use strict;
use Carp;

our $AUTOLOAD;

sub new
{
    my ( $proto, $cpuinfo, $args ) = @_;

    my $class = ref($proto) || $proto;

    my $self = {};

    $self->{_args} = $args;
    $self->{_data} = $cpuinfo;

    bless $self, $class;

    return $self;

}

sub AUTOLOAD
{

    my ($self) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my ($method) = $AUTOLOAD =~ /.*::(.+?)$/;

    if ( exists $self->{_data}->{$method} )
    {
        no strict 'refs';

        *{$AUTOLOAD} = sub {
            my ($self) = @_;
            return $self->{_data}->{$method};
        };

        goto &{$AUTOLOAD};

    }
    else
    {

        if ( $self->{_args}->{NoFatal} )
        {
            return undef;
        }
        else
        {
            croak(
                sprintf(
                    q(Can't locate object method "%s" via package "%s"),
                    $method, ref($self)
                )
            );
        }

    }
}

1;
__END__

=head2 EXPORT

None by default.

=head1 BUGS

The enormous bug in this is that I didnt realize when I made this that
the contents of C</proc/cpuinfo > are different for different processors.

I really would be indebted if Linux users from other than x86 processors
would help me document this properly.

The source can be found at

    https://github.com/jonathanstowe/Linux-Cpuinfo

Please feel free to fork, send patches etc.

=head1 COPYRIGHT AND LICENSE

See the README file in the Distribution Kit

=head1 AUTHOR

Jonathan Stowe, E<lt>jns@gellyfish.co.ukE<gt>

=head1 SEE ALSO

L<perl>.

=cut
