package EntityModel::Web::PSGI;
# ABSTRACT: PSGI support for EntityModel::Web framework
use EntityModel::Class {
	web => { type => 'EntityModel::Web' },
	template => { type => 'EntityModel::Template' },
};
use EntityModel::Web::Context;
use EntityModel::Web::Request;
use EntityModel::Web::Response;

our $VERSION = '0.002';

=head1 NAME

EntityModel::Web::PSGI - serve L<EntityModel::Web> definitions through PSGI

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 # execute via plackup for example: plackup ./app.psgi
 use EntityModel;
 use EntityModel::Web::PSGI;
 # Load a model which includes a web definition
 my $model = EntityModel->new->add_plugin(Web => {
 })->load_from(JSON => {
   file => $ENV{ENTITYMODEL_JSON_MODEL}
 });
 # Create the PSGI wrapper
 my $app = EntityModel::Web::PSGI->new;
 # Set up web and template information
 my ($web) = grep $_->isa('EntityModel::Web'), $model->plugin->list;
 my $tmpl = EntityModel::Template->new(
 	include_path	=> $ENV{ENTITYMODEL_TEMPLATE_PATH}
 );
 $tmpl->process_template(\qq{[% PROCESS Main.tt2 %]});
 $app->template($tmpl);
 $app->web($web);
 # Return our PSGI coderef
 sub { $app->run_psgi(@_) };

=head1 DESCRIPTION

Preliminary support for running L<EntityModel::Web> definitions through
a PSGI interface.

Expects the L</web> L<EntityModel::Web> attribute to be set before any
requests are served, with at least one site definition if you want this
to do anything useful.

Currently also proxies a L</template> attribute, although expect this to
be deprecated in a future version (it really shouldn't be here).

=head1 METHODS

=head2 web

Accessor for the L<EntityModel::Web> definition used for this PSGI instance.
Returns $self if used as a mutator:

 my $web;
 $psgi->web($web)->psgi_request(...);

=head2 template

Accessor for the L<EntityModel::Web> definition used for this PSGI instance.
Returns $self if used as a mutator:

 my $template;
 warn $psgi->template($template)->web;

=cut

=head2 run_psgi

Process a PSGI request. Will be called by the L<PSGI> framework.

=cut

sub run_psgi {
	my $self = shift;
	my $env = shift;

# Populate initial request values from $env
	my $req = EntityModel::Web::Request->new(
		method => lc($env->{REQUEST_METHOD} || ''),
		path => $env->{REQUEST_URI},
		version => $env->{SERVER_PROTOCOL},
		host => $env->{SERVER_NAME},
		port => $env->{SERVER_PORT},
		# Convert HTTP_SOME_HEADER to some_header
		header => [ map {; /^HTTP_(.*)/ ? +{ name => lc($1), value => $env->{$1} } : () } keys %$env ],
	);

# Create our context using this request information
	my $ctx = EntityModel::Web::Context->new(
		request		=> $req,
		template	=> $self->template,
	);
	$ctx->find_page_and_data($self->web);

# Early return if we had no page match
	return $self->psgi_result(
		$env,
		404,
		[],
		'Not found'
	) unless $ctx->page;

# Prepare for page rendering
	$ctx->resolve_data;

# Get a response object
	my $resp = EntityModel::Web::Response->new(
		context => $ctx,
		page => $ctx->page,
		request => $req,
	);
# then ignore it and generate the body and a hardcoded 200 return
# FIXME use proper status code here and support streaming/async!
	my $body = $ctx->process;
	return $self->psgi_result(
		$env,
		200,
		[ 'Content-Type' => 'text/html' ],
		$body
	);
}

=head2 psgi_result

Returns an appropriate PSGI response, either
an arrayref or a coderef depending on server
support for async/streaming.

=cut

sub psgi_result {
	my $self = shift;
	my ($env, $rslt, $hdr, $body) = @_;
	logInfo("Streaming: %s", $env->{'psgi.streaming'} ? 'yes' : 'no');
	return [ $rslt, $hdr, [ $body ] ] unless $env->{'psgi.streaming'};

	return sub {
		my $responder = shift;	
		my $writer = $responder->([
			$rslt,
			$hdr,
		]);
		$writer->write($body);
		$writer->close;
	};
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<PSGI>

=item * L<EntityModel>

=item * L<EntityModel::Web>

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
