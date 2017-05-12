package Markapl::FromHTML;

use warnings;
use strict;
use 5.008;
use Rubyish;
use HTML::PullParser;
# use Data::Dump qw(pp);

our $VERSION = '0.03';

my $indent_offset = 4;

def load($html) {
    $self->{html} = $html;
    $self;
}

def dump {
    return $_ if (defined($_ = $self->{markapl}));
    return $self->convert;
}

def convert {
    return "" unless $self->{html};

    my $p = HTML::PullParser->new(
        doc => $self->{html},
        start => '"S", tagname, @attr',
        text  => '"T", text',
        end   => '"E", tagname',
    );

    my $current_tag = "";
    my @stack = ();
    my $indent = 0;
    while(my $token = $p->get_token) {
        # warn $token->[0],"\n";;
        if ($token->[0] eq 'S') {
            push @stack, { tag => $token->[1], attr => [@$token[2..$#$token]]};
            $indent += 1;
        }
        elsif ($token->[0] eq 'T') {
            unless($token->[1] =~ /^\s*$/s ) {
                push @stack, { text => $token->[1] }
            }
        }
        elsif ($token->[0] eq 'E') {
            # pp $token;
            my @content;
            my $content = pop @stack;
            while (!$content->{tag} || $content->{tag} ne $token->[1]) {
                push @content, $content;
                $content = pop @stack;
            }

            my $start_tag = $content;

            my $indent_str = " " x ($indent * $indent_offset);
            my $indent_str2 = " " x ( ($indent + 1) * $indent_offset);

            my $attr = "";
            my @attr = @{$start_tag->{attr}};
            if (@attr) {
                while (my ($k, $v) = splice(@attr, 0, 2)) {
                    $attr .= qq{ $k => "$v"};
                }
                $attr = "($attr )";
            }

            if (@content == 1) {
                my $content_text = $content[0]->{code};
                if (!$content_text && $content[0]->{text}) {
                    $content_text = "\"$content[0]->{text}\""
                }
                $content_text ||= '';
                push @stack, {
                    code => "\n${indent_str}$start_tag->{tag}${attr} {\n${indent_str2}$content_text\n${indent_str}};\n"
                };
            }
            else {
                for (@content) {
                    if ($_->{text}) {
                        $_->{code} = "outs \"$_->{text}\";";
                        $_->{text} = undef;
                    }
                }
                my $content_code = join "\n", map { $_->{code}||"" } reverse @content;
                # pp $start_tag->{tag}, $start_tag->{indent};
                push @stack, {
                    code => "\n${indent_str}$start_tag->{tag}${attr} {\n${indent_str2}$content_code\n${indent_str}};\n"
                };
            }

            $indent -= 1;
        }
    }

    my $ret = join "\n", "sub {", (map { $_->{code} || $_->{text} } @stack), "\n}\n";

    # Squeeze empty lines.
    $ret =~ s/\n\s*\n/\n/g;
    $ret =~ s/\{\n\s+\}(;?)\n/{}$1\n/g;

    # Re-org all text only blocks to a single line.
    $ret =~ s/\{\n\s+(".+")\n\s+\}(;?)\n/{ $1 }$2\n/g;

    return $ret;
}

1;
__END__

=head1 NAME

Markapl::FromHTML - Convert HTML to Markapl Perl code.


=head1 VERSION

This document describes Markapl::FromHTML version 0.01


=head1 SYNOPSIS

    use Markapl::FromHTML;
    use Perl::Tidy qw(perltidy);

    my $html = <<HTML;
    <h1>Hello World</h1>
    <p>I am very good</p>
    <div><p>I am very good, too</p></div>
    HTML

    my $m = Markapl::FromHTML->new;
    $m->load($html);
    print $m->dump;
    # sub {
    # h1 { "Hello World" }
    # p { "I am very good" }
    # div { p { "I am very good, too" } }
    # }

=head1 DESCRIPTION

This module converts HTML to Markapl perl code.

=head1 INTERFACE

=over

=item new()

Constructor. No args required

=item load( $html_string )

Load HTML string from a scalar.

=item dump

convert the loaded HTML string as markapl code.

=item convert

convert the loaded HTML string as markapl code.

=back

=head1 DEPENDENCIES

L<HTML::PullParser>, L<Rubyish>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-markapl-fromhtml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
