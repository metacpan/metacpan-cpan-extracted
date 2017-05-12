package EntityModel::Web::Apache2::RequestHandler;
BEGIN {
  $EntityModel::Web::Apache2::RequestHandler::VERSION = '0.001';
}
use EntityModel::Class { };

=head1 NAME

EntityModel::Web::Apache2::RequestHandler - website support for L<EntityModel>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use EntityModel::Web::Context;
use EntityModel::Web::Apache2::Request;
use EntityModel::Web::Apache2::Response;
use EntityModel::Template;

use Apache2::Const qw/OK DECLINED REDIRECT SERVER_ERROR MODE_READBYTES NOT_FOUND/;
use Time::HiRes qw(time);

my $tmpl;

sub handler {
	my $r = shift;
	my $start = time;
	my $req = EntityModel::Web::Apache2::Request->new($r);
#	$tmpl ||= EntityModel::Template->new(
#		include_path	=> '/home/tom/dev/EntityTestSite/template'
#	);
#	$tmpl->process_template(\q{[% PROCESS TemplateBlocks.tt2 %]});
	my $ctx = EntityModel::Web::Context->new(
		request	=> $req,
#		template => $tmpl,
	);
	$ctx->find_page_and_data($::WEB);
	$ctx->resolve_data;
	my $resp = EntityModel::Web::Apache2::Response->new($ctx, $r);
	my $rslt = $resp->process;
	my $elapsed = time - $start;
	logError("Page took %7.3fms", 1000.0 * $elapsed);
	return $rslt;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2009-2011. Licensed under the same terms as Perl itself.