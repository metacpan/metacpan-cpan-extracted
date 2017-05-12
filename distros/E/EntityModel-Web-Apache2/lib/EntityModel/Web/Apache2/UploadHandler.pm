package EntityModel::UploadInstance;
BEGIN {
  $EntityModel::UploadInstance::VERSION = '0.001';
}
use EntityModel::Class {
};

sub onstart { logInfo("Starting upload"); }
sub onfilename { logInfo("Filename is [%s]", $_[1]); }
sub oncomplete { logInfo("Complete"); }
sub onheader { logInfo("Header [%s] is [%s]", $_[1], $_[2]); }
sub ondata { logInfo("Data acquired"); }
sub oncancel { logInfo("Cancelled"); }

package EntityModel::Apache2::UploadHandler;
BEGIN {
  $EntityModel::Apache2::UploadHandler::VERSION = '0.001';
}
use EntityModel::Class {
	_logMask => { type => 'debug' }
};

=pod

Upload handler implementation for Apache.

=over 4

=item * onstart - upload has started, this is the first request that comes thorugh

=item * onfilename - we have received filename in the disposition header

=item * onheader - we have a header

=item * ondata - additional data has come through

=item * oncancel - the upload was cancelled

=item * oncomplete - the upload is now complete

=back

=cut

use Apache2::Const	-compile => qw/DECLINED OK M_POST/;
use APR::Const		-compile => qw/SUCCESS/;
use APR::Bucket;
use Apache2::Filter;

use POSIX qw{floor};
use EntityModel::Cache;
use Time::HiRes qw{sleep};
use EntityModel::Web::PageHandler;
use EntityModel::Web::Request::Apache2;
use UNIVERSAL::require;

=head2 C<handler>

Attach the upload handler for POST requests. Requires the following Apache definition:

 <Location /upload/>
  PerlInitHandler EntityModel::UploadHandler
 </Location>

=cut

sub handler : method {
	my ($class, $r) = @_;
	return Apache2::Const::DECLINED unless $r->method_number == Apache2::Const::M_POST;

	logDebug("Attach handler for [%s]", $r->uri);

	EntityModel::Web::PageHandler->reloadSiteDef() unless $::SITE;
	my ($page) = $::SITE->pageFromURI($r->uri);
	return Apache2::Const::DECLINED unless $page && $page->upload;
	$page->upload->require;

	logError("Have upload %s, attaching filter", $page->upload);
	$r->add_input_filter($class . '->updateStatus');
	return Apache2::Const::OK;
}

=head2 C<updateStatus>

=cut

sub updateStatus {
	my ($class, $f, $bucket, $mode, $block, $bytesRead) = @_;
	logError("Have %d bytes", $bytesRead);

	unless($f->ctx) {
		logError("New request, pid %d, URI %s", $$, $f->r->uri);
		my ($page) = $::SITE->pageFromURI($f->r->uri);
		$f->ctx({
			page		=> $page,
			total		=> $f->r->headers_in->get('Content-Length') || 0,
			upload		=> $page->upload->new(r => EntityModel::Web::Request::Apache2->new($f->r)),
		});
		$f->ctx->{upload}->onstart if $f->ctx->{upload}->can('onstart');
		if($f->ctx->{upload}->can('onheader')) {
			$f->r->headers_in->do(sub {
				my ($k, $v) = @_;
				$f->ctx->{upload}->onheader($k, $v);
				1;
			});
		}
	}
	logError("CTX has been set");
	my $upload = $f->ctx->{upload};
	logError("Upload is %s", $upload);

# Check whether the next bucket brigade completed successfully - only update status if it has
	my $rslt = $f->next->get_brigade($bucket, $mode, $block, $bytesRead);

	unless($rslt == APR::Const::SUCCESS) {
		$upload->oncancel if $upload->can('oncancel');
		return $rslt;
	}

# At this point $bucket is a bucket brigade containing required data.
# Retrieve full packet so far. Hopefully this will just be 8Kb and we can parse it sensibly.
	my $content = '';
	my $b = $bucket->first;
	while($b) {
		if($b->read(my $data)) {
			logDebug("Read " . length($data) . " bytes");
			$content .= $data;
			$upload->ondata($data) if $upload->can('ondata');
		}
		$b = $bucket->next($b);
	}
	unless($f->ctx->{filename}) {
		if($content =~ m/^Content-Disposition:\s+(.*?)$/msi) {
			my $disposition = $1;
			logDebug("Disposition: $disposition");
			my ($filename) = ($disposition =~ /filename="([^"]*)"/i);
			logDebug("Filename is [%s]", $filename);
			$f->ctx->{filename} = $filename;
			$upload->onfilename($filename) if $upload->can('onfilename');
		}
	}
	$f->ctx->{completed} += $bucket->length;
	if($f->ctx->{completed} == $f->ctx->{total}) {
		$upload->oncomplete if $upload->can('oncomplete');
	}
	return Apache2::Const::OK;
}

1;
