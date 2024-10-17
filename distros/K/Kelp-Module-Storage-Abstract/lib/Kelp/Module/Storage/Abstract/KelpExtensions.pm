package Kelp::Module::Storage::Abstract::KelpExtensions;
$Kelp::Module::Storage::Abstract::KelpExtensions::VERSION = '1.00';
use Kelp::Base -strict;

use Kelp::Response;
use Try::Tiny;
use Plack::MIME;
use HTTP::Date;
use Scalar::Util qw(blessed);

sub Kelp::Response::render_file
{
	my ($self, $filename) = @_;

	my $app = $self->app;
	my $fh;
	my %info;
	my $e;

	try {
		$fh = $app->storage->retrieve($filename, \%info);
	}
	catch {
		$e = $_;
	};

	if ($e) {
		die $e unless blessed $e;

		if ($e->isa('Storage::Abstract::X::NotFound')) {
			return $self->render_error(404);
		}
		elsif ($e->isa('Storage::Abstract::X::PathError')) {
			return $self->render_error(403);
		}
		else {
			# StorageError or HandleError
			$app->logger(error => "Rendering file failed: $e") if $app->can('logger');
			return $self->render_error(500);
		}
	}

	return $self
		->set_header('Content-Type', Plack::MIME->mime_type($filename) || 'text/plain')
		->set_header('Content-Length', $info{size})
		->set_header('Last-Modified', HTTP::Date::time2str($info{mtime}))
		->render_binary($fh);
}

1;

