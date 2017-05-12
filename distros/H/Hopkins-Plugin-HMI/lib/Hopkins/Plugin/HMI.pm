package Hopkins::Plugin::HMI;
BEGIN {
  $Hopkins::Plugin::HMI::VERSION = '0.900';
}

use strict;
use warnings;

=head1 NAME

Hopkins::Plugin::HMI - hopkins HMI session (using HTTP)

=head1 DESCRIPTION

Hopkins::Plugin::HMI encapsulates the HMI (human machine
interface) POE session created by the manager session.  this
session uses the Server::HTTP component to provide a web
interface to the job server using Catalyst.

=cut

BEGIN { $ENV{CATALYST_ENGINE} = 'Embeddable' }

use base 'Class::Accessor::Fast';

use POE;
use POE::Component::Server::HTTP;

use Class::Accessor::Fast;

use Template;

__PACKAGE__->mk_accessors(qw(kernel manager config app errmsg));

our $catalyst;

=head1 STATES

=over 4

=item new

=cut

sub new
{
	my $self = shift->SUPER::new(@_);

	# load the Catalyst-related bits as late as possible so
	# that we can give it a dynamic configuration.  Catalyst
	# is not very OO minded, so we have to monkey around
	# with its worldview.

	$catalyst->{'Plugin::Authentication'}	= $self->config->{auth};
	$catalyst->{session}					= $self->config->{session};
	$catalyst->{session}->{cookie_name}		= 'hopkins-hmi';
	$catalyst->{hopkins}					= $self->manager;

	require Hopkins::Plugin::HMI::Catalyst;

	$self->app(new Hopkins::Plugin::HMI::Catalyst);

	# handle plugin-specific configuration, then create
	# a POE::Component::Server::HTTP instance that will
	# dispatch incoming requests to the Catalyst instance.

	$self->config->{port} ||= 8088;

	$self->errmsg(join '', <DATA>);

	my %args =
	(
		Port			=> $self->config->{port},
		ContentHandler	=> { '/' => sub { $self->handler(@_) } },
		Headers			=> { Server => "hopkins/$Hopkins::VERSION" }
	);

	new POE::Component::Server::HTTP %args;
}

sub handler
{
	my $self	= shift;
	my $req		= shift;
	my $res		= shift;
	my $app		= $self->app;

	my $obj;
	my @err;

	my $code = $app->handle_request($req, \$obj, \@err);

	# if the request failed, show an error page, but use our
	# own in place of Catalyst's butt ugly one.  process the
	# page using TT in order to show error messages.

	if (not defined $obj or $code == 500) {
		my $template	= new Template;
		my $stash		= { errors => \@err, version => $Hopkins::Plugin::HMI::VERSION };
		my $output		= '';

		$template->process(\$self->errmsg, $stash, \$output);

		$res->content($output);
		$res->code(500);

		return RC_OK;
	}

	# if the content we get back from is an IO::File object,
	# flatten it by reading it in and spitting it back out.

	if (UNIVERSAL::isa($obj->content, 'IO::File')) {
		my $content;

		while (not eof $obj->content) {
			read $obj->content, my ($buf), 64 * 1024;
			$content .= $buf;
		}

		$obj->content($content);
	}

	# Catalyst::Engine::Embeddable->handle_request populates
	# a HTTP::Response object, though PoCo::Server::HTTP has
	# already provided us with one.  transcribe the contents
	# of the catalyst HTTP::Response onto the other instance
	# provided by POE::Component::Server::HTTP.

	$res->header($_ => $obj->header($_))
		foreach $obj->headers->header_field_names;

	$res->code($obj->code);
	$res->content($obj->content);
	$res->message('');

	$req->header(Connection => 'close');

	return RC_OK;
}

=back

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<title>hopkins HMI - error</title>
		<style type="text/css">
			body
			{
				background-color:	#393939;
				font-family:		Tahoma, Arial, Helvetica, sans-serif;
			}

			div
			{
				width:				800px;
				margin:				auto;
				margin-top:			100px;
			}

			div div
			{
				width:				auto;
				margin:				0;
				padding:			20px;
				border:				1px solid #411;
				background-color:	#911;
			}

			h1
			{
				color:				#fff;
				font-size:			2em;
				font-weight:		normal;
				border-bottom:		2px dotted #f88;
				padding-bottom:		10px;
				margin:				0 0 0 0;
			}

			div p
			{
				color:				#ddd;
			}

			span
			{
				color:				#aaa;
				font-size:			0.6em;
				float:				right;
			}
		</style>
	</head>

	<body>
		<div>
			<div>
				<h1>Internal Server Error</h1>

				[% FOREACH error = errors %]
					<p>
						[% error %]
					</p>
				[% END %]
			</div>
			<span>Hopkins::Plugin::HMI [% version %]</span>
		</div>
	</body>
</html>
