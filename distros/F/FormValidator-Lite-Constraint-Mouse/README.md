# NAME

FormValidator::Lite::Constraint::Mouse - Use Mouse's type constraints.

# SYNOPSIS

    use FormValidator::Lite;
    FormValidator::Lite->load_constraints(qw/Mouse/);

    my $validator = FormValidator::Lite->new(CGI->new("flg=1"));
    $validator->check(
       flg => ['Bool']
    );

    #if you wanna use your original constraints.
    use FormValidator::Lite;
    use Mouse::Util::TypeConstraints;

    enum 'HttpMethod' => qw(GET HEAD POST PUT DELETE); #you must load before load 'FormValidator::Lite->load_constraints(qw/Mouse/)'

    FormValidator::Lite->load_constraints(qw/Mouse/);

    my $validator = FormValidator::Lite->new(CGI->new("req_type=GET"));
    $validator->check(
       "req_type => ['HttpMethod']
    );

# DESCRIPTION

This module provides Mouse's type constraint as constraint rule of [FormValidator::Lite](https://metacpan.org/pod/FormValidator::Lite)
If you want to know the constraint, see [Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints) for details.

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# SEE ALSO

[FormValidator::Lite](https://metacpan.org/pod/FormValidator::Lite),[Mouse::Util::TypeConstraints](https://metacpan.org/pod/Mouse::Util::TypeConstraints)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
