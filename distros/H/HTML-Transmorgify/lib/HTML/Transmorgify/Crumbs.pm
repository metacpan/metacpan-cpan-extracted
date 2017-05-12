
package HTML::Transmorgify::Crumbs;

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use HTML::Transmorgify qw(rbuf $result queue_intercept);

our @ISA = qw(HTML::Transmorgify);

our $sign;

my %tags;

sub add_tags
{
	my ($self, $tobj) = @_;
	$self->intercept_shared($tobj, __PACKAGE__, 85, %tags);
}

sub reform
{
	my ($href, $sig) = @_;
	if ($href =~ /\?/) {
		return "$href&%20crumb=$sig";
	} else {
		return "$href?%20crumb=$sig";
	}
}

sub regular_tag
{
	my ($attribute, $attr, $closed) = @_;
	#
	# The point of compiling is to be able to use things 
	# more than once.  Let's copy the href and then use
	# the copy on subsequent executions.
	#
	$attr->set(" $attribute" => $attr->raw($attribute));
	$attr->hide(" $attribute");
	$attr->eval_at_runtime(1);
	rbuf(sub {
		return 1 unless $sign;
		my $href = $attr->get(" $attribute");
		my $sig = $sign->($href);
		$attr->set($attribute => reform($href, $sig))
			if $sig;
		return 1;
	});
	return 1;
}

$tags{a} = \&a_tag;
$tags{img} = \&img_tag;
$tags{frame} = \&frame_tag;
$tags{form} = \&form_tag;
$tags{"/form"} = sub { 1 };

sub a_tag
{
	regular_tag('href', @_);
}

sub img_tag
{
	regular_tag('src', @_);
}

sub frame_tag
{
	regular_tag('src', @_);
}

sub script_tag
{
	# XXX
}

sub form_tag
{
	my ($attr, $closed) = @_;

	my $end_form;

	# called at <form> runtime
	rbuf(sub {
		$end_form = '';
		return 1 unless $sign;
		my $action = $attr->get('action');
		my $sig = $sign->($action);
		if ($sig) {
			$end_form = "<input type=hidden name=' crumb' value='$sig'>";
		}
	});

	my $close_cb = sub {
		rbuf(sub {
			$HTML::Transmorgify::result->[0] .= $end_form;
		});
	};
	queue_intercept(__PACKAGE__,
		"/form"	=> $close_cb,
	);
	1;
}

1;
