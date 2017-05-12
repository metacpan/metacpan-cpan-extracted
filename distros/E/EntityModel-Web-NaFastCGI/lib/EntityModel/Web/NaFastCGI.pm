package EntityModel::Web::NaFastCGI;
# ABSTRACT: L<Net::Async::FastCGI> support for L<EntityModel::Web>
use EntityModel::Class {
	_isa	=> [qw(Net::Async::FastCGI)],
};

our $VERSION = '0.002';

=head1 NAME

EntityModel::Web::NaFastCGI - website support for L<EntityModel>

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use IO::Async::Loop;
 use EntityModel;
 use EntityModel::Template;
 use EntityModel::Web::NaFastCGI;

 my $loop = IO::Async::Loop->new;
 my $model = EntityModel->new->load_from(JSON => { file => 'model.json' });
 my $tmpl = EntityModel::Template->new;
 $tmpl->process_template(\'[% PROCESS TemplateDefs.tt2 %]');
 my $fcgi = EntityModel::Web::NaFastCGI->new(
 	model		=> $model,
 	context_args	=> [
 		template	=> $tmpl,
 	],
 	show_timing	=> 1,
 );

 $loop->add($fcgi);
 $fcgi->listen(
 	service	=> 9738,
 	on_listen_error => sub { die "Listen failed: @_"; },
 	on_resolve_error => sub { die "Resolve failed: @_"; }
 );
 $loop->loop_forever;

=head1 DESCRIPTION

=cut

use EntityModel::Web::Context;
use EntityModel::Web::NaFastCGI::Request;
use EntityModel::Web::NaFastCGI::Response;
use Time::Checkpoint::Sequential;

=head2 configure

=cut

sub configure {
	my $self = shift;
	my %args = @_;
	
	$self->{show_timing} = 0 unless exists $self->{show_timing};

	if(my $model = delete $args{model}) {
		$self->{model} = $model;
		($self->{web}) = grep { $_->isa('EntityModel::Web') } $model->plugin->list;
	}

	foreach (qw(show_timing context_args on_request)) {
		if(defined(my $v = delete $args{$_})) {
			$self->{$_} = $v;
		}
	}

	return $self->SUPER::configure(%args);
}

=head2 on_request

=cut

sub on_request {
	my ($self, $r) = @_;

	my $check = $self->{show_timing} ? Time::Checkpoint::Sequential->new : undef;

	my $req = EntityModel::Web::NaFastCGI::Request->new($r);
	$check->mark('Generate request') if $self->{show_timing};
	$self->maybe_invoke_event('on_request_ready', $self, $req);
	$check->mark('Request callback') if $self->{show_timing};

	my $ctx = EntityModel::Web::Context->new(
		request		=> $req,
		  $self->{context_args}
		? (@{$self->{context_args}})
		: ()
	);
	$check->mark('Context') if $self->{show_timing};
	$self->maybe_invoke_event('on_context', $self, $ctx);
	$check->mark('Context callback') if $self->{show_timing};

# Do the page lookup immediately
	$ctx->find_page_and_data($self->{web});
	$check->mark('Find page') if $self->{show_timing};

	unless($ctx->page) {
		$self->maybe_invoke_event('on_page_not_found', $self, $ctx);
		return;
	}

	$self->maybe_invoke_event('on_page', $self, $ctx);
	$check->mark('Page callback') if $self->{show_timing};

# Defer the data resolution step
	$self->get_loop->later($self->_capture_weakself(sub {
		my $self = shift;
		$check->reset_timer if $self->{show_timing};
		$ctx->resolve_data;
		$check->mark('Resolve data') if $self->{show_timing};

# And also defer actual page generation, in an attempt to make page handling slightly fairer
		$self->get_loop->later(sub {
			$check->reset_timer if $self->{show_timing};
			my $resp = EntityModel::Web::NaFastCGI::Response->new($ctx, $r);
			$check->mark('Create response') if $self->{show_timing};
			$self->maybe_invoke_event('on_response', $self, $resp);
			$check->mark('Response callback') if $self->{show_timing};
			my $rslt = $resp->process;
			$check->mark('Process response') if $self->{show_timing};
			my $elapsed = 0;
			undef $check;
			printf("200 OK %s\n", $req->path);
		});
	}));
	return;
}

sub on_page_not_found {
	my $self = shift;
	warn "No page was found\n";
	return;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
