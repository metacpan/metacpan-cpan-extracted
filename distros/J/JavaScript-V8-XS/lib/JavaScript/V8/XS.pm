package JavaScript::V8::XS;
use strict;
use warnings;
use parent 'Exporter';

use Text::Trim qw(trim rtrim);
use XSLoader;

our $VERSION = '0.000002';
XSLoader::load( __PACKAGE__, $VERSION );

our @EXPORT_OK = qw[];

sub _get_js_source_fragment {
    my ($context, $range) = @_;

    $range //= 5;
    foreach my $frame (@{ $context->{frames} }) {
        open my $fh, '<', $frame->{file};
        if (!$fh) {
            # TODO: error message?
            return;
        }
        my $lineno = 0;
        my @lines;
        while (my $line = <$fh>) {
            ++$lineno;
            next unless $lineno >= ($frame->{line} - $range);
            $frame->{line_offset} = $lineno unless exists $frame->{line_offset};

            last unless $lineno <= ($frame->{line} + $range);
            push @lines, rtrim($line);
        }
        $frame->{lines} = \@lines;
    }
}

sub parse_js_stacktrace {
    my ($self, $stacktrace_lines, $desired_frames) = @_;

    $desired_frames //= 1;

    # @contexts => [ {
    #   message => "undefined variable foo",
    #   frames => [ {
    #       file => 'foo.js',
    #       line => 232,  # line 232 is the one with the error
    #       line_offset => 230, # first line in @lines is 230
    #       lines => [
    #           "function a()",
    #           "{",
    #           "  return foo.length",
    #           "}",
    #       ],
    #   }, {...} ]
    #   } ]
    my @contexts;
    foreach my $line (@$stacktrace_lines) {
        $line = trim($line);
        next unless $line;

        my @texts = split /\n/, $line;
        my %context;
        $context{frames} = [];
        foreach my $text (@texts) {
            $text = trim($text);
            next unless $text;

            $context{message} = $text unless exists $context{message};

            next unless $text =~ m/^\s*at\s*(\S*)\s*\(([^:]*):([0-9]+)(:([0-9]+))?\)\s*$/;
            push @{ $context{frames} //= [] }, {
                file => $2,
                line => $3,
            };
            last if scalar @{ $context{frames} } >= $desired_frames;
        }
        next unless exists $context{message};
        _get_js_source_fragment(\%context);
        push @contexts, \%context;
    }
    return \@contexts;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

JavaScript::V8::XS - Perl XS binding for the V8 JavaScript engine

=head1 VERSION

Version 0.000002

=head1 SYNOPSIS

  use JavaScript::V8::XS;
  my $v8 = JavaScript::V8::XS->new();

=head1 SEE ALSO

L<< https://metacpan.org/pod/JavaScript::V8 >>
L<< https://metacpan.org/pod/JavaScript::Duktape::XS >>

=head1 AUTHOR

=over 4

=item * Gonzalo Diethelm C<< gonzus AT cpan DOT org >>

=back

=head1 THANKS

=over 4

=item * Authors of JavaScript::V8

=back

=cut
