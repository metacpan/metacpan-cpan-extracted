package Function::Return;

use v5.14.0;
use warnings;

our $VERSION = "0.041";

use attributes ();
use Sub::Util ();
use Sub::Info ();
use Scalar::Util ();
use Scope::Upper ();
use Function::Parameters;

our $DEFAULT_ATTR_NAME = 'Return';

my %IMPORT;
sub import {
    my $pkg = caller;
    my $class = shift;
    my %args = @_;

    $IMPORT{name} = exists $args{name} ? $args{name} : $DEFAULT_ATTR_NAME;
    $IMPORT{no_check} = exists $args{no_check} ? $args{no_check} : !!0;

    no strict qw(refs);
    *{"${pkg}::FETCH_CODE_ATTRIBUTES"} = \&_FETCH_CODE_ATTRIBUTES;
    *{"${pkg}::MODIFY_CODE_ATTRIBUTES"} = \&_MODIFY_CODE_ATTRIBUTES;
}

my %ATTR;
my @DECLARATIONS;
sub _FETCH_CODE_ATTRIBUTES {
    my ($pkg, $sub, @attrs) = @_;
    return @{$ATTR{$sub}||[]};
}

sub _MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $sub, @attrs) = @_;

    for my $attr (@attrs) {
        next unless $attr =~ _attr_re();
        my $types = $1;
        my $evaled = eval("package $pkg; [$types]");
        $types = $evaled unless $@;

        push @DECLARATIONS => {
            pkg   => $pkg,
            sub   => $sub,
            types => $types,
        }
    }
    $ATTR{$sub} = [ grep { !_attr_re() } @attrs ];
    return;
}

sub _attr_re {
    return qr!
        ^
        $IMPORT{name}
        \((.*?)\)
        $
    !x;
}

sub no_check { $IMPORT{no_check} }

sub _croak {
    my (undef, $file, $line) = caller 1;
    die @_, " at $file line $line.\n"
}

sub wrap_sub {
    my $class = shift;
    my ($sub, $types) = @_;

    my $sub_info  = Sub::Info::sub_info($sub);
    my $shortname = $sub_info->{name};

    { # check type
        my $file = $sub_info->{file};
        my $line = $sub_info->{start_line};
        for my $type (@$types) {
            for (qw/check get_message/) {
                die "Invalid type: $type. require `$_` method at $file line $line.\n"
                    unless $type->can($_)
            }
        }
    }

    my $src = q|
sub {
    _croak "Required list context in fun $shortname because of multiple return values function"
        if @$types > 1 && !wantarray;

    # force LIST context.
    my @ret = &Scope::Upper::uplevel($sub, @_, &Scope::Upper::CALLER(0));

    # return Empty List
    return if @$types == 0 && !@ret;

    _croak "Too few return values for fun $shortname (expected @$types, got @{[map { defined $_ ? $_ : 'undef' } @ret]})" if @ret < @$types;
    _croak "Too many return values for fun $shortname (expected @$types, got @{[map { defined $_ ? $_ : 'undef' } @ret]})" if @ret > @$types;

    for my $i (0 .. $#$types) {
        my $type  = $types->[$i];
        my $value = $ret[$i];
        _croak "Invalid return in fun $shortname: return $i: @{[$type->get_message($value)]}" unless $type->check($value);
    }

    return @$types > 1 ? @ret # multi return
         : $ret[0]            # single return
};
|;

    my $code = eval $src; ## no critic
    if ($@) {
        _croak $@;
    }
    return $code;
}

sub _get_parameters_info {
    my $sub = shift;
    return Function::Parameters::info($sub);
}

sub _set_parameters_info {
    my ($info, $sub) = @_;

    my $key = Function::Parameters::_cv_root($sub);
    return Function::Parameters::_register_info(
        $key,
        $info->keyword,
        $info->nshift,
        map {
            my $params = $info->{"_$_"};
            [ map { $_->name, $_->type } @$params ]
        } qw(
            positional_required
            positional_optional
            named_required
            named_optional
        ),
        $info->slurpy ? ($info->slurpy->name, $info->slurpy->type) : (),
    );
}

our %metadata;
sub info {
    my ($func) = @_;
    my $key = Scalar::Util::refaddr $func or return undef;
    my $info = $metadata{$key} or return undef;
    require Function::Return::Info;
    Function::Return::Info->new(
        types => $info->{types},
    )
}

sub _register_return_info {
    my ($func, $types) = @_;
    my $key = Scalar::Util::refaddr $func or return undef;

    my $info = {
        types => $types
    };

    $metadata{$key} = $info;
}

sub CHECK {
    for my $decl (@DECLARATIONS) {
        my ($pkg, $sub, $types)  = @$decl{qw(pkg sub types)};

        if (no_check) {
            _register_return_info($sub, $types);
            next;
        }

        my $subname   = Sub::Util::subname($sub);
        my $prototype = Sub::Util::prototype($sub);
        my @attr      = attributes::get($sub);
        my $pinfo     = _get_parameters_info($sub);

        my $wrapped = __PACKAGE__->wrap_sub($sub, $types);

        Sub::Util::set_subname($subname, $wrapped);
        Sub::Util::set_prototype($prototype, $wrapped) if $prototype;
        _set_parameters_info($pinfo, $wrapped) if $pinfo;
        {
            no warnings qw(misc);
            attributes::->import($pkg, $wrapped, @attr) if @attr;
        }
        _register_return_info($wrapped, $types);

        no strict qw(refs);
        no warnings qw(redefine);
        *{$subname} = $wrapped;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Return - specify a function return type

=head1 SYNOPSIS

    use Function::Return;
    use Types::Standard -types;

    sub foo :Return(Int) { 123 }
    sub bar :Return(Int) { 3.14 }

    foo(); # 123
    bar(); # ERROR! Invalid type

    # multi return values
    sub baz :Return(Num, Str) { 3.14, 'message' }
    my ($pi, $msg) = baz();
    my $count = baz(); # ERROR! Required list context.

    # empty return
    sub boo :Return() { return; }
    boo();

=head1 DESCRIPTION

Function::Return allows you to specify a return type for your functions.

=head2 SUPPORT

This module supports all perl versions starting from v5.14.

=head2 IMPORT OPTIONS

=head3 name

you can change C<Return> to your own name:

    use Function::Return name => 'MyReturn';

    sub foo :MyReturn(Str) { }

=head3 no_check

you can switch off type check:

    use Function::Return no_check => 1;

    sub foo :Return(Int) { 3.14 }
    foo(); # NO ERROR!

=head2 METHODS

=head3 Function::Return::info($coderef)

The function C<Function::Return::info> lets you introspect return values like L<Function::Parameters::Info>:

    use Function::Return;

    sub baz() :Return(Str) { 'hello' }

    my $rinfo = Function::Return::info \&baz;

    $rinfo->types; # [Str]
    $rinfo->isa('Function::Return::Info');

In addition, it can be used with L<Function::Parameters>:

    use Function::Parameters;
    use Function::Return;

    fun baz() :Return(Str) { 'hello' }

    my $pinfo = Function::Parameters::info \&baz;
    my $rinfo = Function::Return::info \&baz;

This makes it possible to know both type information of function arguments and return value at compile time, making it easier to use for testing etc.

=head3 Function::Return->wrap_sub($coderef)

This interface is for power-user. Rather than using the C<< :Return >> attribute, it's possible to wrap a coderef like this:

    my $wrapped = Function::Return->wrap_sub($orig, [Str]);
    $wrapped->();

=head1 NOTE

=head2 enforce LIST to simplify

C<Function::Return> makes the original function is called in list context whether the wrapped function is called in list, scalar, void context:

    sub foo :Return(Str) { wantarray ? 'LIST!!' : 'NON!!' }
    my $a = foo(); # => LIST!!

The specified type checks against the value the original function was called in the list context.

C<wantarray> is convenient, but it sometimes causes confusion. So, in this module, we prioritized that the expected type of function return value becomes easy to understand.

=head2 requirements of type constraint

The requirements of type constraint of C<Function::Return> is the same as for C<Function::Parameters>. Specific requirements are as follows:

> The only requirement is that the returned value (here referred to as $tc, for "type constraint") is an object that provides $tc->check($value) and $tc->get_message($value) methods. check is called to determine whether a particular value is valid; it should return a true or false value. get_message is called on values that fail the check test; it should return a string that describes the error.

=head2 compare Return::Type

Both C<Return::Type> and C<Function::Return> perform type checking on the return value of the function, but there are some differences.

1. C<Function::Return> is not possible to specify different type constraints for scalar and list context.

2. C<Function::Return> check type constraint for void context.

3. C<Function::Return::info> and C<Function::Parameters::info> can be used together.

=head1 SEE ALSO

L<Function::Parameters>, L<Return::Type>

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

