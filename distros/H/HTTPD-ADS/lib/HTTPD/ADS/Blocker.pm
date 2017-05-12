package HTTPD::ADS::Blocker;
use strict;
use Carp;
use IPC::Cmd qw[can_run run];

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = 0.1;
    @ISA         = qw (Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw ();
    @EXPORT_OK   = qw ();
    %EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the documentation for this module. 


=head1 NAME

HTTPD::ADS::Blocker - Block a given IP address using some technique or other.

=head1 SYNOPSIS

  use HTTPD::ADS::Blocker



=head1 DESCRIPTION

This is a wrapper. The idea is that various techniques might be available
to block communication with a blacklisted IP address. Right now is just
one: install a reject route. The interface, therefore, to this module
is still evolving but the default will always use the reject route technique.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), HTTPD::ADS .

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 sample_function

 Usage     : How to use this function/method
 Purpose   : What it does
 Returns   : What it returns
 Argument  : What it wants to know
 Throws    : Exceptions and other anomolies
 Comments  : This is a sample subroutine header.
           : It is polite to include more pod and fewer comments.

See Also   : 

=cut

################################################## subroutine header end ##


    sub new
{
    my ($class, %parameters) = @_;
    
    my $self = bless ({}, ref ($class) || $class);
    &reject($parameters{ip});
    return ($self);
}

sub reject {
    my $ipaddr = shift;
    my $route_full_path = can_run('route') or die "cannot find the route command";
    my @routecmd = ($route_full_path, qw(add foo reject));
    $routecmd[2]=$ipaddr;
    
    unless (run(command => \@routecmd, verbose =>0))
    {
	my $errmesg = (scalar localtime)." failed to add reject route for $ipaddr (maybe its already listed?)\n ";
	carp $errmesg;
    }
}

1; #this line is important and will help the module return a true value
__END__

