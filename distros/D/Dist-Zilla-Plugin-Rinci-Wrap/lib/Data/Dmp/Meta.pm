package Data::Dmp::Meta;

our $DATE = '2016-06-02'; # DATE
our $VERSION = '0.13'; # VERSION

use 5.010001;
use strict;
use warnings;

use Scalar::Util qw(looks_like_number blessed reftype refaddr);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dd dmp);

# for when dealing with circular refs
our %_seen_refaddrs;
our %_subscripts;
our @_fixups;

our $OPT_PERL_VERSION;

# BEGIN COPY PASTE FROM Data::Dump
my %esc = (
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

# put a string value in double quotes
sub _double_quote {
    local($_) = $_[0];

    # If there are many '"' we might want to use qq() instead
    s/([\\\"\@\$])/\\$1/g;
    return qq("$_") unless /[^\040-\176]/;  # fast exit

    s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

    # no need for 3 digits in escape for these
    s/([\0-\037])(?!\d)/sprintf('\\%o',ord($1))/eg;

    s/([\0-\037\177-\377])/sprintf('\\x%02X',ord($1))/eg;
    s/([^\040-\176])/sprintf('\\x{%X}',ord($1))/eg;

    return qq("$_");
}
# END COPY PASTE FROM Data::Dump

sub _dump {
    my ($val, $subscript, $opts) = @_;

    my $ref = ref($val);
    if ($ref eq '') {
        if (!defined($val)) {
            return "undef";
        } elsif (looks_like_number($val)) {
            return $val;
        } else {
            return _double_quote($val);
        }
    }
    my $refaddr = refaddr($val);
    $_subscripts{$refaddr} //= $subscript;
    if ($_seen_refaddrs{$refaddr}++) {
        push @_fixups, " " if @_fixups;
        push @_fixups, "\$a->$subscript = \$a",
            ($_subscripts{$refaddr} ? "->$_subscripts{$refaddr}" : ""), ";";
        return "'fix'";
    }

    my $class;

    if ($ref eq 'Regexp' || $ref eq 'REGEXP') {
        require Regexp::Stringify;
        return Regexp::Stringify::stringify_regexp(
            regexp=>$val, with_qr=>1, plver=>$OPT_PERL_VERSION);
    }

    if (blessed $val) {
        $class = $ref;
        $ref = reftype($val);
    }

    my $res;
    if ($ref eq 'ARRAY') {
        $res = "[";
        my $i = 0;
        for (@$val) {
            $res .= ", " if $i;
            $res .= _dump($_, "$subscript\[$i]", $opts);
            $i++;
        }
        $res .= "]";
    } elsif ($ref eq 'HASH') {
        $res = "{";
        my $i = 0;
        for (sort keys %$val) {
            $res .= ", " if $i++;
            my $k = /\W/ ? _double_quote($_) : $_;
            my $v = _dump($val->{$_}, "$subscript\{$k}", $opts);
            $res .= "$k=>$v";
        }
        $res .= "}";
    } elsif ($ref eq 'SCALAR') {
        $res = "\\"._dump($$val, $subscript, $opts);
    } elsif ($ref eq 'REF') {
        $res = "\\"._dump($$val, $subscript, $opts);
    } else {
        $res = "$opts->{old_data}\->$subscript";
    }

    $res = "bless($res, "._double_quote($class).")" if defined($class);
    $res;
}

our $_is_dd;
sub _dd_or_dmp {
    local %_seen_refaddrs;
    local %_subscripts;
    local @_fixups;

    my $opts = shift;

    my $res;
    if (@_ > 1) {
        $res = "(" . join(", ", map {_dump($_, '', $opts)} @_) . ")";
    } else {
        $res = _dump($_[0], '', $opts);
    }
    if (@_fixups) {
        $res = "do { my \$a = $res; " . join("", @_fixups) . " \$a }";
    }

    if ($_is_dd) {
        say $res;
        return @_;
    } else {
        return $res;
    }
}

sub dd { local $_is_dd=1; _dd_or_dmp(@_) }
sub dmp { goto &_dd_or_dmp }

1;
# ABSTRACT: A fork of Data::Dmp

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Dmp::Meta - A fork of Data::Dmp

=head1 VERSION

This document describes version 0.13 of Data::Dmp::Meta (from Perl distribution Dist-Zilla-Plugin-Rinci-Wrap), released on 2016-06-02.

=head1 SYNOPSIS

 use Data::Dmp::Meta;

 $SPEC{foo} = {
     v => 1.1,
     args => { arg1=>{schema=>'str*'} },
     completion => sub { "blah" },
 };

 dd {old_data=>'$SPEC{foo}'}, $SPEC{foo};

will output something like:

 { args => {arg1=>{schema=>'str*'}}, completion=>$SPEC{foo}->{completion}, v=>1.1 }

=head1 DESCRIPTION

Like L<Data::Dmp>, but when encountering a coderef (or other unknown type), will
refer to an item in a structure.

Will probably be generalized and extracted to its own dist in the future.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Rinci-Wrap>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Dist-Zilla-Plugin-Rinci-Wrap>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Rinci-Wrap>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
