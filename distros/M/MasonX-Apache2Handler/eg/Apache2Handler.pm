#!/usr/bin/perl
#--------------------------------------------------
#
#	Mason Apache2Handler.pm
#
#	Built for multiple sites, mutiple component
#	roots.
#
#	Feb 25, 2004
#	Beau E. Cox
#	<beau@beaucox.com><http://beaucox.com>
#
#--------------------------------------------------

package MyApache::Apache2Handler;

use strict;
use warnings;

use Apache2 ();
use lib ( $ENV{MOD_PERL_INC} );

use Apache::Request ();
use Apache::Cookie ();
use CGI ();
use CGI::Cookie ();

our %ah = ();

#	Mason w/Apache support
use MasonX::Apache2Handler;

#	Modules my components will use
{
    package HTML::Mason::Commands;
	
    use Apache::Const -compile => ':common';
    use APR::Const -compile => ':common';
    use ModPerl::Const -compile => ':common';

    use Apache::Session;
    use MasonX::Request::WithApache2Session;

    use DBI;
    use Data::Dumper;
    use Image::Magick;
    use Date::Format;
    use Net::IP::CMatch;
    use HTML::Lint;

}

setup_sites();

#	actual request handler
sub handler
{
    my ($r) = @_;

#   DON'T allow internal components (starting with '_')
    my $fn = $r->filename;
    if ($fn =~ m{.*/(.*)} && $1 && $1 =~ /^_/) {
	my $rip = $r->connection->remote_ip;
	$r->log_error ("attempt to access internal component: $fn remote ip: $rip\n");
	return Apache::NOT_FOUND;
    }

#   allow only text/xxx content type
    return -1 if $r->content_type && $r->content_type !~ m|^text/|i;

#   find site and handler: dispatch request
    my $site = $r->dir_config ('mason_site');

    unless( $site ) {
	$r->log_error ("no 'mason_site' specified\n");
	return Apache::NOT_FOUND;
    }
    unless( $ah{$site} ) {
	setup_sites( $r, $site );
	unless( $ah{$site} ) {
	    $r->log_error ("no 'ah' found for 'mason_site' $site\n");
	    return Apache::NOT_FOUND;
	}
    }

    my $status = $ah{$site}->handle_request ($r);

#   special error handling here (email, etc...)
    $status;
}

#   set up an ApacheHandler2 for each site
sub setup_sites
{
    my ( $r, $site ) = shift;
    my @asites = ();
    if( $site ) {
	push @asites, $site;
    } else {
	my $sites = $ENV{MASON_SITES};
	return unless $sites;
	@asites = split /:/, $sites;
    }
    for my $site( @asites ) {
	next if $ah{$site};
	my @args =
	    (
	     args_method		=> "mod_perl",
	     comp_root                  => $ENV{MASON_COMP_ROOT}."/$site",
	     data_dir                   => $ENV{MASON_DATA_ROOT}."/$site",
	     error_mode                 => 'output',
	     request_class             =>'MasonX::Request::WithApache2Session',
	     session_allow_invalid_id   => 'yes',
	     session_cookie_name        => "beaucox-$site-cookie",
	     session_cookie_domain      => '.beaucox.com',
	     session_cookie_expires     => '+7d',
	     session_class              => 'Apache::Session::MySQL',
	     session_data_source        => "dbi:mysql:${site}_sessions",
	     session_user_name          => 'mysql',
	     session_password           => 'mysql',
	     session_lock_data_source   => "dbi:mysql:${site}_sessions",
	     session_lock_user_name     => 'mysql',
	     session_lock_password      => 'mysql',
	     session_use_cookie         => 'yes',
	     );
	push @args, $r if $r;
	$ah{$site} = new MasonX::Apache2Handler( @args );
    }
}

1;			

__END__
