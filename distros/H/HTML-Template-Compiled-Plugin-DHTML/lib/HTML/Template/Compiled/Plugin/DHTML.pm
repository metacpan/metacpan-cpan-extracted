package HTML::Template::Compiled::Plugin::DHTML;
use strict;
use warnings;
our $VERSION = "0.03";
use Data::TreeDumper;
use Data::TreeDumper::Renderer::DHTML;
use HTML::Template::Compiled;

HTML::Template::Compiled->register(__PACKAGE__);

sub register {
    my ($class) = @_;
    my %plugs = (
        escape => {
            DHTML => \&dumper,
        },
    );
    return \%plugs;
}

sub dumper {
	my ($var) = @_;
	my $style;
	my $body = DumpTree($var, 'Data',
		DISPLAY_ROOT_ADDRESS => 1,
		DISPLAY_PERL_ADDRESS => 1,
		DISPLAY_PERL_SIZE => 1,
		RENDERER => {
			NAME => 'DHTML',
			STYLE => \$style,
			BUTTON => {
				COLLAPSE_EXPAND => 1,
				SEARCH => 1,
			}
		}
	);
	return $style.$body;
}


my $version_pod = <<'=cut';

=head1 NAME

HTML::Template::Compiled::Plugin::DHTML - Dumps variables into clickable HTML output

=head1 VERSION

$VERSION = "0.03"

=cut

sub __test_version {
    my $v = __PACKAGE__->VERSION;
    my ($v_test) = $version_pod =~ m/VERSION\s*=\s*"(.+)"/m;
    no warnings;
    return $v eq $v_test ? 1 : 0;
}

1;

__END__

=pod

=head1 SYNOPSIS

    use HTML::Template::Compiled::Plugin::DHTML;

    my $htc = HTML::Template::Compiled->new(
        plugin => [qw(HTML::Template::Compiled::Plugin::DHTML)],
        ...
    );

=head1 METHODS

=over 4

=item register

gets called by HTC

=item dumper

Dumps variables into clickable HTML. See L<examples/dhtml.html>.

=back

=cut


