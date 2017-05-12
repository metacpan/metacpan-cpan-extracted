package TestParseFile;

use strict;
use warnings;

use Test::More;

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;

    $self->_init(@_);

    return $self;
}

sub _filename {
    my $self = shift;

    if (@_) {
        $self->{_filename} = shift;
    }

    return $self->{_filename};
}

sub _text {
    my $self = shift;

    if (@_) {
        $self->{_text} = shift;
    }

    return $self->{_text};
}

sub _init {
    my ($self, $args) = @_;

    $self->_filename($args->{fn});

    $self->_text(_slurp_to_ref($self->_filename()));

    return;
}

sub _slurp_to_ref {
    my $filename = shift;
    my $text;

    local $/;
    open my $in, '<', $filename
        or Carp::confess( "Cannot open $filename" );
    $text = <$in>;
    close($in);

    return \$text;
}

sub parse {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $re, $msg) = @_;

    my $verdict = ok (scalar(${$self->_text()} =~ s{$re}{}ms), $self->format_msg($msg));

    if (!$verdict ) {
        diag('Filename == ' . $self->_filename());
    }

    return $verdict;
}

sub consume {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $prefix, $msg) = @_;

    my $verdict =
        is( substr(${$self->_text()}, 0, length($prefix)),
            $prefix,
            $self->format_msg($msg));

    if ($verdict) {
        ${$self->_text()} = substr(${$self->_text()}, length($prefix));
    }
    else {
        diag('Filename == ' . $self->_filename());
    }

    return $verdict;
}

sub is_end {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $msg) = @_;

    my $verdict = is (${$self->_text()}, "", $self->format_msg($msg));

    if (!$verdict ) {
        diag("Filename == " . $self->_filename());
    }

    return $verdict;
}

=head2 $file_parser->parse_paras(\@paras, $message)

Parse the paragraphs paras. Paras can either be strings, in which case
they'll be considered plain texts. Or they can be hash refs with the key
're' pointing to a regex string.

Here's an example:

    my @synopsis_paras = (
        '=head1 SYNOPSIS',
        'Quick summary of what the module does.',
        'Perhaps a little code snippet.',
        { re => q{\s*} . quotemeta(q{use MyModule::Test;}), },
        { re => q{\s*} .
            quotemeta(q{my $foo = MyModule::Test->new();})
            . q{\n\s*} . quotemeta("..."), },
    );

    $mod1->parse_paras(
        \@synopsis_paras,
        'MyModule::Test - SYNOPSIS',
    );

=cut

sub parse_paras {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $paras, $msg) = @_;

    # Construct a large regex.
    my $regex =
        join '',
        map { $_.q{\n\n+} }
        map { (ref($_) eq 'HASH') ? $_->{re} : quotemeta($_) }
        @{$paras};

    return $self->parse( $regex, $msg );
}

sub format_msg {
    my ($self, $msg) = @_;

    return $msg;
}

package TestParseModuleFile;

use vars qw(@ISA);

@ISA = qw(TestParseFile);

sub _perl_name {
    my $self = shift;

    if (@_) {
        $self->{_perl_name} = shift;
    }

    return $self->{_perl_name};
}

sub _dist_name {
    my $self = shift;

    if (@_) {
        $self->{_dist_name} = shift;
    }

    return $self->{_dist_name};
}

sub _author_name {
    my $self = shift;

    if (@_) {
        $self->{_author_name} = shift;
    }

    return $self->{_author_name};
}

sub _license {
    my $self = shift;

    if (@_) {
        $self->{_license} = shift;
    }

    return $self->{_license};
}

sub _init {
    my ($self, $args) = @_;

    $self->SUPER::_init($args);

    $self->_perl_name($args->{perl_name});

    $self->_dist_name($args->{dist_name});

    $self->_author_name($args->{author_name});

    $self->_license($args->{license});

    return;
}

sub format_msg {
    my ($self, $msg) = @_;

    return $self->_perl_name() . " - $msg";
}

sub _chomp_me {
    my $string = shift;
    chomp($string);
    return $string;
}

sub _get_license_blurb {
    my $self = shift;

    my $texts =
    {
        'perl' =>
            [_chomp_me(<<'EOF')],
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
EOF

        'mit' =>
        [
            _chomp_me(<<'EOF'),
This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>
EOF
            _chomp_me(<<'EOF'),
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:
EOF
            _chomp_me(<<'EOF'),
The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
EOF
            _chomp_me(<<'EOF'),
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
EOF
        ],
        'bsd' =>
        [
            split(/\n\n+/, <<"EOF")
This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/bsd-license.php>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of @{[$self->_author_name()]}'s Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
EOF
        ],
        'gpl' =>
        [
            split(/\n\n+/, <<"EOF")
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
EOF
        ],
        'lgpl' =>
        [
            split(/\n\n+/, <<"EOF")
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA.
EOF
        ],
    };

    return @{$texts->{$self->_license()}};
}

# TEST:$cnt=0;
sub parse_module_start {
    my $self = shift;

    my $perl_name = $self->_perl_name();
    my $dist_name = $self->_dist_name();
    my $author_name = $self->_author_name();
    my $lc_dist_name = lc($dist_name);

    # TEST:$cnt++;
    $self->parse(
        qr/\Apackage \Q$perl_name\E;\n\nuse warnings;\nuse strict;\n\n/ms,
        'start',
    );

    {
        my $s1 = qq{$perl_name - The great new $perl_name!};

        # TEST:$cnt++;
        $self->parse(
            qr/\A=head1 NAME\n\n\Q$s1\E\n\n/ms,
            "NAME Pod.",
        );
    }

    # TEST:$cnt++;
    $self->parse(
        qr/\A=head1 VERSION\n\nVersion 0\.01\n\n=cut\n\nour \$VERSION = '0\.01';\n+/,
        "module version",
    );

    {
        my @synopsis_paras =
        (
            '=head1 SYNOPSIS',
            'Quick summary of what the module does.',
            'Perhaps a little code snippet.',
            { re => q{\s*} . quotemeta(qq{use $perl_name;}), },
            { re => q{\s*} .
                quotemeta(q{my $foo = } . $perl_name . q{->new();})
                . q{\n\s*} . quotemeta('...'),
            },
        );

        # TEST:$cnt++
        $self->parse_paras(
            \@synopsis_paras,
            'SYNOPSIS',
        );
    }

    # TEST:$cnt++
    $self->parse_paras(
        [
            '=head1 EXPORT',
            (
"A list of functions that can be exported.  You can delete this section\n"
. "if you don't export anything, such as for a purely object-oriented module."
            ),
        ],
        "EXPORT",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 FUNCTIONS",
            "=head2 function1",
            "=cut",
            "sub function1 {\n}",
        ],
        "function1",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head2 function2",
            "=cut",
            "sub function2 {\n}",
        ],
        "function2",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 AUTHOR",
            { re => quotemeta($author_name) . q{[^\n]+} },
        ],
        "AUTHOR",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 BUGS",
            { re =>
                  q/Please report any bugs.*C<bug-/
                . quotemeta($lc_dist_name)
                .  q/ at rt\.cpan\.org>.*changes\./
            },
        ],
        "BUGS",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 SUPPORT",
            { re => q/You can find documentation for this module.*/ },
            { re => q/\s+perldoc / . quotemeta($perl_name), },
            "You can also look for information at:",
            "=over 4",
        ],
        "Support 1",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            { re => q/=item \* RT:[^\n]*/, },
            "L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=$dist_name>",
        ],
        "Support - RT",
    );


    # TEST:$cnt++
    $self->parse_paras(
        [
            { re => q/=item \* AnnoCPAN:[^\n]*/, },
            "L<http://annocpan.org/dist/$dist_name>",
        ],
        "AnnoCPAN",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            { re => q/=item \* CPAN Ratings[^\n]*/, },
            "L<http://cpanratings.perl.org/d/$dist_name>",
        ],
        "CPAN Ratings",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            { re => q/=item \* Search CPAN[^\n]*/, },
            "L<http://search.cpan.org/dist/$dist_name/>",
        ],
        "CPAN Ratings",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=back",
        ],
        "Support - =back",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 ACKNOWLEDGEMENTS",
        ],
        "acknowledgements",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=head1 COPYRIGHT & LICENSE",
            { re =>
                  q/Copyright \d+ /
                . quotemeta($author_name)
                . q/\./
            },
            $self->_get_license_blurb(),
        ],
        "copyright",
    );

    # TEST:$cnt++
    $self->parse_paras(
        [
            "=cut",
        ],
        "=cut POD end",
    );

    # TEST:$cnt++
    $self->consume(
        qq{1; # End of $perl_name},
        "End of module",
    );

    return;
}

1;

# TEST:$parse_module_start_num_tests=$cnt;
