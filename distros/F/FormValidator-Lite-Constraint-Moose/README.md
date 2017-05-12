# NAME

FormValidator::Lite::Constraint::Moose - Use Moose's type constraints.

# SYNOPSIS

    use FormValidator::Lite;
    FormValidator::Lite->load_constraints(qw/Moose/);

    my $validator = FormValidator::Lite->new(CGI->new("flg=1"));
    $validator->check(
       flg => ['Bool']
    );

    #if you wanna use your original constraints.
    use FormValidator::Lite;
    use Moose::Util::TypeConstraints;

    enum 'HttpMethod' => [qw(GET HEAD POST PUT DELETE)]; #you must load before load 'FormValidator::Lite->load_constraints(qw/Moose/)'

    FormValidator::Lite->load_constraints(qw/Moose/);

    my $validator = FormValidator::Lite->new(CGI->new("req_type=GET"));
    $validator->check(
       "req_type => ['HttpMethod']
    );



# DESCRIPTION

This module provides Moose's type constraint as constraint rule of [FormValidator::Lite](http://search.cpan.org/perldoc?FormValidator::Lite)
If you want to know the constraint, see [Moose::Util::TypeConstraints](http://search.cpan.org/perldoc?Moose::Util::TypeConstraints) for details.

# AUTHOR

Hideaki Ohno <hide.o.j55 {at} gmail.com>

# SEE ALSO

[FormValidator::Lite](http://search.cpan.org/perldoc?FormValidator::Lite),[Moose::Util::TypeConstraints](http://search.cpan.org/perldoc?Moose::Util::TypeConstraints)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
