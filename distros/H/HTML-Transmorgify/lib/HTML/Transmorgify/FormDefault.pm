
package HTML::Transmorgify::FormDefault;

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use HTML::Transmorgify qw(dangling %variables $query_param $debug queue_intercept queue_capture run $debug rbuf postbuf capture_compile);
use URI::Escape;
use HTML::Entities;
use Scalar::Util qw(refaddr blessed);
use YAML;
require Exporter;

our @ISA = qw(HTML::Transmorgify Exporter);
our @EXPORT = qw(validate_form_submission);

my %tags;
my $tag_package = { tag_package => __PACKAGE__ };

our @rtmp;
our $default_enable = 1;

sub add_tags
{
	my ($self, $tobj) = @_;
	$self->intercept_shared($tobj, __PACKAGE__, 65, %tags);
}

our @btmp;

sub return_true { 1 }

$tags{input} = undef;
$tags{button} = undef;
$tags{textarea} = undef;
$tags{"/textarea"} = undef;
$tags{select} = undef;
$tags{"/select"} = undef;
$tags{option} = undef;
$tags{"/option"} = undef;
$tags{"/form"} = \&dangling;
$tags{form} = \&form_tag;

sub qpval
{
	my ($name, $value) = @_;
	return '' unless $query_param->{$name};
	if (ref $query_param->{$name}) {
		if (defined $value) {
			return grep { $_ eq $value } @{$query_param->{$name}};
		} else {
			return '';
		}
	} else {
		if (defined $value) {
			return $query_param->{$name} eq $value;
		} else {
			return $query_param->{$name};
		}
	}
}

sub compile_time_gate 
{
	my ($attr) = @_;
	unless ($attr->boolean('auto_default', undef, 1, raw => 1)) {
		print STDERR "GATE: Bailing early from $attr\n" if $debug;
		return 0;
	}
	if  ($attr->boolean('readonly', undef, 0, raw => 1)) {
		print STDERR "GATE: Bailing early from $attr is read-only\n" if $debug;
		return 0;
	}
	$attr->hide('no_auto_defaults');
	$attr->hide('readonly');
	print STDERR "GATE: compile time okay for $attr\n" if $debug;
	return 1;
}

sub run_time_gate 
{
	my ($attr) = @_;
	unless ($query_param && %$query_param) {
		print STDERR "GATE: No query parameters\n" if $debug;
		return 0;
	}
	unless ($attr->boolean('auto_default', undef, 1)) {
		print STDERR "GATE: Bailing late from $attr\n" if $debug;
		return 0;
	}
	if  ($attr->boolean('readonly', undef, 0)) {
		print STDERR "GATE: Bailing late from $attr is read-only\n" if $debug;
		return 0;
	}
	my $name = $attr->get('name') 
		|| $attr->get('id');
	unless ($name) {
		print STDERR "GATE: No name or id for $attr\n" if $debug;
		return 0;
	}
	unless (exists $query_param->{$name}) {
		print STDERR "GATE: No user input for $attr\n" if $debug;
		return 0;
	}
	print STDERR "GATE: run time time okay for $attr\n" if $debug;
	return $name;
};

sub form_tag 
{
	my ($fattr, $closed) = @_;
	die if $closed;

	my $default;
	
	return unless compile_time_gate($fattr);

	my $text_cb = sub {
		my ($attr, $closed) = @_;

		rbuf(sub {
			return 1 unless run_time_gate($attr);
			$attr->set(value => qpval($attr->get('name')));
		});
	};

	my $vals = {};

	my $radio_cb = sub {
		my ($attr, $closed) = @_;

		rbuf(sub {
			my $name = run_time_gate($attr);
			return 1 unless $name;
			my $value = $attr->get('value');
			if (qpval($name, $value)) {
				$attr->set(checked => undef);
			} else {
				$attr->set(checked => 0);
				$attr->hide('checked');
			}
			return 1;
		});
	};

	my $nothing = sub { 1 };

	my $input_cb = sub {
		my ($attr, $closed) = @_;

		return 1 unless compile_time_gate($attr);

		my %handlers = (
			text		=> $text_cb,
			password	=> $text_cb,
			radio		=> $radio_cb,
			checkbox	=> $radio_cb,
			submit		=> $nothing,
			hidden		=> $nothing,
			reset		=> $nothing,
			file		=> $nothing, 	# if we have some sort of caching, cache it!
			image		=> $nothing,
			button		=> $nothing,
		);

		my $type = lc($attr->get('type'));
		die unless $handlers{$type};
		$handlers{$type}->($attr, $closed);
		$attr->eval_at_runtime(1);
		return 1;
	};

	my $textarea_cb = sub {
		my ($attr, $closed) = @_;
		return 1 unless compile_time_gate($attr);

		$attr->eval_at_runtime(1);
		my ($b, $deferred) = capture_compile('textarea', $attr, undef, %HTML::Transmorgify::queued_intercepts);

		my $b2 = [];
		{
			local($HTML::Transmorgify::rbuf) = $b2;
			for my $ccb (@HTML::Transmorgify::queued_captures) {
				$ccb->($b);
			}
		}

		postbuf(sub {
			my $name = run_time_gate($attr);

			if ($name) {
				$HTML::Transmorgify::result->[0] .= encode_entities(qpval($name)) . "</textarea>";
			} else {
				run($b);
				run($b2);
				$deferred->doit();
				$HTML::Transmorgify::result->[0] .= "</textarea>";
			}
		});
		return 1;
	};

	my $select_cb = sub {
		my ($attr, $closed) = @_;
		return 1 unless compile_time_gate($attr);
		$attr->eval_at_runtime(1);

		my $option_cb = sub {
			my ($oattr, $closed) = @_;
			return 1 unless compile_time_gate($attr);

			$oattr->eval_at_runtime(1);

			my $get_value;
			if (defined $oattr->raw('value')) {
				$get_value = sub {
					$oattr->get('value');
				};
			} else {
				my $b;
				queue_capture(sub {
					$b = shift;
				});
				$get_value = sub {
					local(@btmp) = ('');
					run($b, \@btmp);
					return $btmp[0];
				};
			}

			rbuf(sub {
				my $name = run_time_gate($attr);
				return 1 unless $name;

				my $value = $get_value->();

				if (qpval($name, $value)) {
					$oattr->set(selected => undef);
				} else {
					$oattr->set(selected => 0);
					$oattr->hide('selected');
				}
			});
		};
		
		queue_intercept(__PACKAGE__,
			option		=> $option_cb,
			"/select",	=> sub { 1 },
		);
	};


	queue_intercept(__PACKAGE__,
		input		=> $input_cb,
		textarea	=> $textarea_cb,
		select		=> $select_cb,
		'/form'		=> \&return_true,
	);
	return 1;
};


__END__


