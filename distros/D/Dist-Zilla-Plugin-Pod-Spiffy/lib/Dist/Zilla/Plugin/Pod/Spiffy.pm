package Dist::Zilla::Plugin::Pod::Spiffy;

use strict;
use warnings;

our $VERSION = '1.001007'; # VERSION

use Moose;
with qw/Dist::Zilla::Role::FileMunger/;
use Acme::CPANAuthors;
use namespace::autoclean -also => qr/^__/;

sub munge_file {
        my ($self, $file) = @_;
        return unless $file->name =~ /\.(?:p[lm]|t)$/;

        my $content = $file->content;
        $content =~ s/
            ^=for\s+  pod_spiffy  \s+ (?<args>.+?) (?=\n\n)
            |
            ^=begin\s+ pod_spiffy \s+ (?<args>.+?) ^=end\s+ pod_spiffy \s+\n
        / __munge_args( $+{args} ) /sexmg;

        $file->content( $content );

        return;
}

sub __munge_args {
    my $in = shift;
    $in =~ s/\s+/ /g;
    my @ins = split /\s*\|\s*/, $in;

    my $theme = 'http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons';
    # my $theme = 'http://zcms';
    my $method_icons = __method_icons($theme);
    my $section_bits = __section_bits($theme);
    my $out;
    for ( @ins ) {
        s/^\s+|\s+$//g;
        if ( s/^authors?\s+// ){
            $out .= ' ' . __process_authors($theme, $_);
            next;
        }

        tr/ /_/;
        if ( s/^((?:start|end)_[^_]+)_section// ) {
            $out .= $section_bits->{$1} ? ' ' . $section_bits->{$1} : '';
            next;
        }
        elsif ( /^hr$/ ) {
            $out .= qq{<div style="background: url($theme/hr.png);}
                . q{height: 18px;"></div>};
        }

        next unless $method_icons->{$_};
        $out .= ' ' . $method_icons->{$_};
    }

    return '' unless $out;
    return '=for html ' . $out;
}

sub __process_authors {
    my ( $theme, $authors ) = @_;

    my @authors = $authors =~ /\S+/g;
    my $out;
    my $auth = Acme::CPANAuthors->new;
    for ( map uc, @authors ) {
        my $url = $auth->avatar_url($_) || '';
        $out .= qq{
            <span style="display: inline-block; text-align: center;">
                <a href="http://metacpan.org/author/$_">
                    <img src="$url" alt="$_"
                        style="display: block;
                            margin: 0 3px 5px 0!important;
                            border: 1px solid #666;
                            border-radius: 3px;
                        ">
                    <span style="color: #333; font-weight: bold;">$_</span>
                </a>
            </span>
        };
    }

    $out =~ s/\s*\n\s*/ /g;
    $out =~ s/\s+$//g;
    return $out;
}

sub __section_bits {
    my $theme = shift;

    my @section_pics = qw/
        section-author.png
        section-bugs.png
        section-code.png
        section-contributors.png
        section-experimental.png
        section-github.png
        section-warning.png
    /;

    my %bits;
    for my $pic ( @section_pics ) {
        ( my $name = $pic ) =~ s/section-|\.png//g;
        $name =~ tr/-/_/;
        $bits{"start_$name"} = qq{<div style="display: table; height: 91px;
                background: url($theme/$pic) no-repeat left;
                padding-left: 120px;"
            ><div style="display: table-cell; vertical-align: middle;">};
        $bits{"end_$name"} = '</div></div>';
    }

    s/\s*\n\s*/ /g for values %bits;
    return \%bits;
}

sub __method_icons {
    my $theme = shift;
    return {
        in_arrayref => qq{<img alt="" src="$theme/in-arrayref.png">},
        in_hashref  => qq{<img alt="" src="$theme/in-hashref.png">},
        in_key_value  => qq{<img alt="" src="$theme/in-key-value.png">},
        in_list  => qq{<img alt="" src="$theme/in-list.png">},
        in_no_args  => qq{<img alt="" src="$theme/in-no-args.png">},
        in_object  => qq{<img alt="" src="$theme/in-object.png">},
        in_scalar_optional
            => qq{<img alt="" src="$theme/in-scalar-optional.png">},
        in_scalar_or_arrayref
            => qq{<img alt="" src="$theme/in-scalar-or-arrayref.png">},
        in_scalar  => qq{<img alt="" src="$theme/in-scalar.png">},
        in_scalar_scalar_optional
            => qq{<img alt="" src="$theme/in-scalar-scalar-optional.png">},
        in_subref => qq{<img alt="" src="$theme/in-subref.png">},
        out_arrayref => qq{<img alt="" src="$theme/out-arrayref.png">},
        out_error_exception
            => qq{<img alt="" src="$theme/out-error-exception.png">},
        out_error_undef_list
            => qq{<img alt="" src="$theme/out-error-undef-list.png">},
        out_error_undef
            => qq{<img alt="" src="$theme/out-error-undef.png">},
        out_hashref => qq{<img alt="" src="$theme/out-hashref.png">},
        out_key_value => qq{<img alt="" src="$theme/out-key-value.png">},
        out_list_or_arrayref
            => qq{<img alt="" src="$theme/out-list-or-arrayref.png">},
        out_list => qq{<img alt="" src="$theme/out-list.png">},
        out_object => qq{<img alt="" src="$theme/out-object.png">},
        out_scalar => qq{<img alt="" src="$theme/out-scalar.png">},
        out_subref => qq{<img alt="" src="$theme/out-subref.png">},
    };
}

q|
Creativity is the feeling you get when you realize
your project is due tomorrow
|;

__END__

=encoding utf8

=head1 NAME

Dist::Zilla::Plugin::Pod::Spiffy - make your documentation look spiffy as HTML

=for test_synopsis BEGIN { die "SKIP: Not needed\n"; }

=for Pod::Coverage munge_file

=for stopwords octocat subref subrefs themeing unvolunteer

=head1 SYNOPSIS

In your POD:

    =head2 C<my_super_function>

    =for pod_spiffy in no args | out error undef or list|out hashref

    This function takes two arguments, one of them is mandatory. On
    error it returns either undef or an empty list, depending on the
    context. On success, it returns a hashref.

    ...

    =head1 REPOSITORY

    =for pod_spiffy start github section

    Fork this module on https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy

    =for pod_spiffy end github section

    ...

    =head1 AUTHORS

    =for pod_spiffy authors ZOFFIX JOE SHMOE

    =head1 CONTRIBUTORS

    =for pod_spiffy authors SOME CONTRIBUTOR


In your C<dist.ini>:

    [Pod::Spiffy]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin lets you make your documentation look
spiffy as HTML, by adding meaningful icons. If you're viewing this document
as HTML, you can see available icons below.

The main idea behind this module isn't so much the looks, however, but
the provision of visual hints and clues about various sections of your
documentation, and more importantly the arguments and return values
of the methods/functions.

=head1 HISTORY

I was impressed by L<ETHER|http://metacpan.org/author/ETHER>'s work on
L<Acme::CPANAuthors::Nonhuman> (the including author avatars in the docs
part) and appreciated the added value HTML content can bring to
the POD in my L<Acme::Dump::And::Dumper>.

While working on the implementation of the horribly inconsistent
L<WWW::Goodreads|https://github.com/zoffixznet/WWW-Goodreads>,
I wanted my users to not have to remember the
type of return values for 74+ methods. That's when I thought up the idea
of including icons to give hints of the return types.

=head1 THEME

The current theme is hardcoded to use
C<http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/> However,
since most icons are size-unbound, themeing should be extremely
easy in the future, and configuration option will be provided very soon.

=head1 NOTE ON SCALARS

I realize that hashrefs, subrefs, arrayrefs, and the ilk are all scalars,
but this documentation and the icons by scalars mean the
plain, non-reference types; i.e. strings and numbers (C<42>, C<"foo">, etc.)

=head1 IN YOUR POD

To spiffy-up your POD, use the C<=for> POD command, followed by
C<pod_spiffy>, followed by codes (see L<SYNOPSIS> for examples).
For icons, you can specify multiple icon codes separated with a
pipe character (C<|>). For example:

    =for pod_spiffy in no args

    =for pod_spiffy in no args | out error undef list

You can have any amount of whitespace between individual
words of the codes (but
you must have at least some whitespace). Whitespace around the
C<|> separator is irrelevant.

The following codes are currently available:

=head2 INPUT ARGUMENTS ICONS

These icons provide hints on what your sub/method takes as an argument.

=head3 C<in no args>

    =for pod_spiffy in no args

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-no-args.png">

Use this icon to indicate your sub/method does not take any arguments.

=head3 C<in scalar>

    =for pod_spiffy in scalar

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar.png">

Use this icon to indicate your sub/method takes a plain
scalar as an argument.

=head3 C<in scalar scalar optional>

    =for pod_spiffy in scalar scalar optional

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-scalar-optional.png">

Use this icon to indicate your sub/method takes as arguments one
mandatory and one optional arguments, both of which are plain
scalars.

=head3 C<in arrayref>

    =for pod_spiffy in arrayref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-arrayref.png">

Use this icon to indicate your sub/method takes an arrayref as an argument.

=head3 C<in hashref>

    =for pod_spiffy in hashref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-hashref.png">

Use this icon to indicate your sub/method takes an hashref as an argument.

=head3 C<in key value>

    =for pod_spiffy in key value

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png">

Use this icon to indicate your sub/method takes a list of
key/value pairs as an argument
(e.g. C<< ->method( foo => 'bar', ber => 'biz' ); >>.

=head3 C<in list>

    =for pod_spiffy in list

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-list.png">

Use this icon to indicate your sub/method takes a list
of scalars as an argument (e.g. C<qw/foo bar baz ber/>)

=head3 C<in object>

    =for pod_spiffy in object

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-object.png">

Use this icon to indicate your sub/method takes an object as an argument.

=head3 C<in scalar optional>

    =for pod_spiffy in scalar optional

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png">

Use this icon to indicate your sub/method takes a
single B<optional> argument that is a scalar.

=head3 C<in scalar or arrayref>

    =for pod_spiffy in scalar or arrayref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-or-arrayref.png">

Use this icon to indicate your sub/method takes either
a plain scalar or an arrayref as an argument.

=head3 C<in subref>

    =for pod_spiffy in subref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-subref.png">

Use this icon to indicate your sub/method takes a subref as an argument.

=head2 OUTPUT ON ERROR ICONS

These icons are to indicate what your sub/method returns if an
error occurs during its execution.

=head3 C<out error exception>

    =for pod_spiffy out error exception

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-error-exception.png">

Use this icon to indicate your sub/method on error throws an exception.

=head3 C<out error undef or list>

    =for pod_spiffy out error undef or list

=for html <span>Icon: </span>



Use this icon to indicate your sub/method on error returns
either C<undef> or an empty list, depending on the context.

=head3 C<out error undef>

    =for pod_spiffy out error undef

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-error-undef.png">

Use this icon to indicate your sub/method on error returns
C<undef> (regardless of the context).

=head2 OUTPUT ICONS

These icons are to indicate what your sub/method returns after
a successful     execution.

=head3 C<out scalar>

    =for pod_spiffy out scalar

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

Use this icon to indicate your sub/method returns a plain scalar.

=head3 C<out arrayref>

    =for pod_spiffy out arrayref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-arrayref.png">

Use this icon to indicate your sub/method returns an arrayref.

=head3 C<out hashref>

    =for pod_spiffy out hashref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-hashref.png">

Use this icon to indicate your sub/method returns a hashref.

=head3 C<out key value>

    =for pod_spiffy out key value

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-key-value.png">

Use this icon to indicate your sub/method returns a list of
key value pairs (i.e., return is suitable to assign to a hash).

=head3 C<out list>

    =for pod_spiffy out list

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-list.png">

Use this icon to indicate your sub/method returns a list of
things (i.e., return is suitable to assign to an array).

=head3 C<out list or arrayref>

    =for pod_spiffy out list or arrayref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-list-or-arrayref.png">

Use this icon to indicate your sub/method returns either a list of
things or an arrayref, depending on the context.

=head3 C<out subref>

    =for pod_spiffy out subref

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-subref.png">

Use this icon to indicate your sub/method returns a subref.

=head3 C<out object>

    =for pod_spiffy out object

=for html <span>Icon: </span>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

Use this icon to indicate your sub/method returns a object.

=head2 SECTION ICONS

To use a section icon, you need to indicate both the start of the section
and the end of it, e.g.:

    =for pod_spiffy start github section

    =head3 GITHUB REPO

    Fork this module on github https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy

    =for pod_spiffy end github section

Available icons are:

=head3 Github Repo

    =for pod_spiffy start github section

    Fork this module on GitHub:
    L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy>

    =for pod_spiffy end github section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

=head3 Authors

    =for pod_spiffy start author section

    Joe Shmoe wrote this module

    =for pod_spiffy end author section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

B<See also:> L<CPAN Authors> section below, for a way to include
author avatars.

=head3 Contributors

    =for pod_spiffy start contributors section

        Joe More also contributed to this module

    =for pod_spiffy end contributors section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

B<See also:> L<CPAN Authors> section below, for a way to include
author avatars.

=head3 Bugs

    =for pod_spiffy start bugs section

    Report bugs for this module on
    L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy/issues>

    =for pod_spiffy end bugs section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

=head3 Code

    =for pod_spiffy start code section

        print "Yey\n" for 1..42;

    =for pod_spiffy end code section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

I'm unsure of the use for this icon. Originally it was planned to be
used with the SYNOPSIS code. The icon will likely be changed in appearance
and the C<code> section might become more versatile, to be used
with all chunks of code.

=head3 Warning

    =for pod_spiffy start warning section

    Warning! If you try this something might explode!

    =for pod_spiffy end warning section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-warning.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

Use this section icon to indicate a warning.

=head3 Experimental

    =for pod_spiffy start experimental section

    This method is still experimental!

    =for pod_spiffy end experimental section

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-experimental.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html <p>This is an example</p>

=for html  </div></div>

Use this section to hint about the features described being experimental.

=head2 OTHER FEATURES

=head3 CPAN Authors

    =for pod_spiffy author ZOFFIX ETHER MSTROUT

Adds an avatar of the author, and their PAUSE
ID. To use this feature use C<authors> code, followed by a
whitespace separated list of PAUSE author IDs, for example:

=for html <p>Example:</p>

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span> <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ETHER"> <img src="http://www.gravatar.com/avatar/bdc5cd06679e732e262f6c1b450a0237?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2Fbdc5cd06679e732e262f6c1b450a0237" alt="ETHER" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ETHER</span> </a> </span> <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/MSTROUT"> <img src="http://www.gravatar.com/avatar/524737fe496a440995d96c27e67387ed?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F4e8e2db385219e064e6dea8fbd386434" alt="MSTROUT" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">MSTROUT</span> </a> </span>

=head3 Horizontal Rule

    =for pod_spiffy hr

=for html <p>Example:</p>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

A simple horizontal rule. You can use it, for example, to separate
groups of methods.

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Dist-Zilla-Plugin-Pod-Spiffy/issues>

If you can't access GitHub, you can email your request
to C<bug-Dist-Zilla-Plugin-Pod-Spiffy at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut