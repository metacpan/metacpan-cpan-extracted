package Full::Pragmata;

use strict;
use warnings;

our $VERSION = '1.003'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use utf8;

=encoding utf8

=head1 NAME

Full::Pragmata - common pragmata for Perl scripts and modules

=head1 SYNOPSIS

 # in your script or module:
 use Full::Pragmata;
 # use strict, warnings, utf8 etc. are all now applied and in scope

=head1 DESCRIPTION

Perl has many modules and features, including some features which are somewhat discouraged
in recent code.

This module attempts to provide a good set of functionality for writing code without too
many lines of boilerplate. It has been extracted from L<Myriad::Class> so that it can be
used in other code without pulling in too many irrelevant dependencies.

=head2 Language features

The following Perl language features and modules are applied to the caller:

=over 4

=item * L<strict>

=item * L<warnings>

=item * L<utf8>

=item * L<perlsub/signatures>

=item * no L<indirect>

=item * no L<multidimensional>

=item * no L<bareword::filehandles>

=item * L<Syntax::Keyword::Try>

=item * L<Syntax::Keyword::Dynamically>

=item * L<Syntax::Keyword::Defer> - or the standard Perl built-in defer since C< :v2 >

=item * L<Syntax::Operator::Equ> - added in C< :v2 >

=item * L<Future::AsyncAwait>

=item * L<Future::AsyncAwait::Hooks> - added in C< :v2 >

=item * provides L<Scalar::Util/blessed>, L<Scalar::Util/weaken>, L<Scalar::Util/refaddr>

=item * provides L<List::Util/min>, L<List::Util/max>, L<List::Util/sum0>

=item * provides L<List::Util/uniqstr> - added in C< :v2 >

=item * provides L<List::Keywords/any>, L<List::Keywords/all>

=item * provides L<JSON::MaybeUTF8/encode_json_text>, L<JSON::MaybeUTF8/encode_json_utf8>,
L<JSON::MaybeUTF8/decode_json_text>, L<JSON::MaybeUTF8/decode_json_utf8>, L<JSON::MaybeUTF8/format_json_text>

=item * provides L<Unicode::UTF8/encode_utf8>, L<Unicode::UTF8/decode_utf8>

=back

In addition, the following core L<feature>s are enabled:

=over 4

=item * L<bitwise|feature>

=item * L<current_sub|feature>

=item * L<evalbytes|feature>

=item * L<fc|feature>

=item * L<postderef_qq|feature>

=item * L<state|feature>

=item * L<unicode_eval|feature>

=item * L<unicode_strings|feature>

=back

=head2 Constraints and checks

L<Data::Checks> is imported with the following constraints available:

=over 4

=item * Defined

=item * Object

=item * Str

=item * Num

=item * StrEq

=item * NumGT

=item * NumGE

=item * NumLE

=item * NumLT

=item * NumRange

=item * NumEq

=item * Isa

=item * ArrayRef

=item * HashRef

=item * Callable

=item * Maybe

=item * Any

=item * All

=back

Note that L<Data::Checks> provides the underlying support for constraints, but
actual usage involves a combination of other modules:

=head3 Field constraints

These are supported through L<Object::Pad::FieldAttr::Checked>:

 package Example;
 use Full::Class qw(:v2);
 field $checked :Checked(Str);

=head3 Other features

This also makes available a L<Log::Any> instance in the C<$log> package variable,
and for L<OpenTelemetry> support you get C<$tracer> as an L<OpenTelemtry::Tracer>
instance.

=head2 VERSIONING

A version tag is required:

 use Full::Pragmata qw(:v1);

Currently C<:v1> is the only version available. It's very likely that future versions
will bring in new functionality or enable/disable a different featureset, or may
remove functionality or behaviour that's no longer appropriate.

=cut

no indirect qw(fatal);
no multidimensional;
no bareword::filehandles;
use mro;
use experimental qw(signatures);
use meta;
no warnings qw(meta::experimental);
use curry;
use Data::Checks;
use Object::Pad::FieldAttr::Checked;
use Sublike::Extended;
use Signature::Attribute::Checked;
use Future::AsyncAwait;
use Future::AsyncAwait::Hooks;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Syntax::Keyword::Defer;
use Syntax::Keyword::Match;
use Syntax::Operator::Equ;
use Scalar::Util;
use List::Util;
use List::Keywords;
use Future::Utils;
use Module::Load ();

use JSON::MaybeUTF8;
use Unicode::UTF8;

use Log::Any qw($log);
use Metrics::Any;

use constant USE_OPENTELEMETRY => $ENV{USE_OPENTELEMETRY};

BEGIN {
    if(USE_OPENTELEMETRY) {
        require OpenTelemetry;
        require OpenTelemetry::Context;
        require OpenTelemetry::Trace;
        require OpenTelemetry::Constants;
    }
}

sub import ($called_on, $version_tag, %args) {
    die "invalid version, expecting something like use @{[caller]} qw(:v1);"
        unless my $version = $version_tag =~ /^:v([0-9]+)/;

    my $pkg = $args{target} // caller(0);

    my $class = __PACKAGE__;

    # Apply core syntax and rules
    strict->import;
    warnings->import;
    utf8->import;

    # We want mostly the 5.36 featureset, but since that includes `say` and `switch`
    # we need to customise the list somewhat
    feature->import(qw(
        bitwise
        current_sub
        evalbytes
        fc
        postderef_qq
        state
        unicode_eval
        unicode_strings
    ));

    # Indirect syntax is problematic due to `unknown_sub { ... }` compiling and running
    # the block without complaint, and only failing at runtime *after* the code has
    # executed once - particularly unfortunate with try/catch
    indirect->unimport(qw(fatal));
    # Multidimensional array access - $x{3,4} - is usually a sign that someone wanted
    # `@x{3,4}` or similar instead, so we disable this entirely
    multidimensional->unimport;
    # Plain STDIN/STDOUT/STDERR are still allowed, although hopefully never used by
    # service code - new filehandles need to be lexical.
    bareword::filehandles->unimport;

    # This one's needed for nested scope, e.g. { package XX; use Full::Service; method xxx (%args) ... }
    experimental->import('signatures');

    # We don't really care about diamond inheritance, since microservices are expected
    # to have minimal inheritance in the first place, but might as well have a standard
    # decision to avoid surprises in future
    mro::set_mro($pkg => 'c3');

    # Helper functions which are used often enough to be valuable as a default
    Scalar::Util->export($pkg => qw(refaddr blessed weaken));
    List::Util->export($pkg => qw(min max sum0));

    # Additional features in :v2 onwards
    List::Util->export($pkg => qw(uniqstr));
    # eval "package $pkg; use Object::Pad::FieldAttr::Checked; use Data::Checks qw(NumGE); 1" or die $@;
    Object::Pad::FieldAttr::Checked->import($pkg);
    Sublike::Extended->import($pkg);
    Signature::Attribute::Checked->import($pkg);
    Data::Checks->import(qw(
        Defined
        Object
        Str
        Num
        StrEq
        NumGT
        NumGE
        NumLE
        NumLT
        NumRange
        NumEq
        Isa
        ArrayRef
        HashRef
        Callable
        Maybe
        Any
        All
    ));

    {
        no strict 'refs';
        *{$pkg . '::' . $_} = JSON::MaybeUTF8->can($_) for qw(
            encode_json_text
            encode_json_utf8
            decode_json_text
            decode_json_utf8
            format_json_text
        );
        *{$pkg . '::' . $_} = Unicode::UTF8->can($_) for qw(
            encode_utf8
            decode_utf8
        );
    }
    {
        no strict 'refs';
        *{$pkg . '::' . $_} = Future::Utils->can($_) for qw(
            fmap_void
            fmap_concat
            fmap_scalar
            fmap0
            fmap1
        );
    }

    {
        no strict 'refs';
        # trim() might appear in core perl at some point, so let's reserve the
        # word and include a basic implementation first. Avoiding Text::Trim
        # here because it sometimes returns an empty list, which would be
        # dangerous - my %hash = (key => trim($value)) for example.
        *{$pkg . '::trim'} = sub ($txt) {
            return undef unless defined $txt;
            $txt =~ s{^\s+}{};
            $txt =~ s{\s+$}{};
            return $txt;
        };
    }

    # Some well-designed modules provide direct support for import target
    Syntax::Keyword::Try->import_into($pkg, try => ':experimental(typed)');
    Syntax::Keyword::Dynamically->import_into($pkg);
    Syntax::Keyword::Defer->import_into($pkg);
    Syntax::Operator::Equ->import_into($pkg);
    Future::AsyncAwait->import_into($pkg, ':experimental(cancel)');
    Metrics::Any->import_into($pkg, '$metrics');

    Future::AsyncAwait::Hooks->import_into($pkg);

    # Others use lexical hints
    List::Keywords->import(qw(any all));
    Syntax::Keyword::Match->import(qw(match));

    {
        no strict 'refs';
        if(USE_OPENTELEMETRY) {
            my $provider = OpenTelemetry->tracer_provider;
            *{$pkg . '::tracer'}  = \($provider->tracer(
                name    => $args{app} // 'perl',
                version => $args{version} // $version,
            ));
        }
        *{$pkg . '::log'} = \Log::Any->get_logger(
            category => $pkg
        );
    }

    return $pkg;
}

1;

__END__

=head1 AUTHOR

Original code can be found at https://github.com/deriv-com/perl-Myriad/tree/master/lib/Myriad/Class.pm,
by Deriv Group Services Ltd. C<< DERIV@cpan.org >>. This version has been split out as a way to provide
similar functionality.

=head1 LICENSE

Released under the same terms as Perl itself.

