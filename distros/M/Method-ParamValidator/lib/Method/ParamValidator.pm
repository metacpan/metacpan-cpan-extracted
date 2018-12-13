package Method::ParamValidator;

$Method::ParamValidator::VERSION   = '0.14';
$Method::ParamValidator::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Method::ParamValidator - Configurable method parameter validator.

=head1 VERSION

Version 0.14

=cut

use 5.006;
use JSON;
use Data::Dumper;

use Method::ParamValidator::Key::Field;
use Method::ParamValidator::Key::Method;
use Method::ParamValidator::Exception::InvalidMethodName;
use Method::ParamValidator::Exception::MissingParameters;
use Method::ParamValidator::Exception::InvalidParameterDataStructure;
use Method::ParamValidator::Exception::MissingRequiredParameter;
use Method::ParamValidator::Exception::MissingMethodName;
use Method::ParamValidator::Exception::MissingFieldName;
use Method::ParamValidator::Exception::UndefinedRequiredParameter;
use Method::ParamValidator::Exception::FailedParameterCheckConstraint;

use Moo;
use namespace::autoclean;

has [ qw(fields methods) ] => (is => 'rw');
has 'config' => (is => 'ro', predicate => 1);

=head1 DESCRIPTION

It provides easy way to configure and validate method parameters. It is  going to
help configure and validate all my packages WWW::Google::*.It is just a prototype
as of now but will be extended as per the requirements.

=head1 SYNOPSIS

=head2 Setting up method validator manually.

    use strict; use warnings;
    use Test::More;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new;
    $validator->add_field({ name => 'firstname', format => 's' });
    $validator->add_field({ name => 'lastname',  format => 's' });
    $validator->add_field({ name => 'age',       format => 'd' });
    $validator->add_field({ name => 'sex',       format => 's' });

    $validator->add_method({ name   => 'add_user',
                             fields => { firstname => 1, lastname => 1, age => 1, sex => 0 }});

    throws_ok { $validator->validate('get_xyz')  }     qr/Invalid method name received/;
    throws_ok { $validator->validate('add_user') }     qr/Missing parameters/;
    throws_ok { $validator->validate('add_user', []) } qr/Invalid parameters data structure/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }) } qr/Parameter failed check constraint/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 10, sex => 's' }) } qr/Parameter failed check constraint/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }) } qr/Missing required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }) } qr/Undefined required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F' }) } qr/Missing required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'X' })  } qr/Parameter failed check constraint/;
    lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'UK' }) };
    lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'uk' }) };

    done_testing();

=head2 Setting up method validator using configuration file.

Sample configuration file in C<JSON> format.

    { "fields"  : [ { "name" : "firstname", "format" : "s" },
                    { "name" : "lastname",  "format" : "s" },
                    { "name" : "age",       "format" : "d" },
                    { "name" : "sex",       "format" : "s" }
                  ],
      "methods" : [ { "name"  : "add_user",
                      "fields": { "firstname" : "1",
                                  "lastname"  : "1",
                                  "age"       : "1",
                                  "sex"       : "0"
                                }
                    }
                  ]
    }

Then you just need one line to get everything setup using the above configuration file C<config.json>.

    use strict; use warnings;
    use Test::More;
    use Test::Exception;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new({ config => "config.json" });

    throws_ok { $validator->validate('get_xyz')  }     qr/Invalid method name received/;
    throws_ok { $validator->validate('add_user') }     qr/Missing parameters/;
    throws_ok { $validator->validate('add_user', []) } qr/Invalid parameters data structure/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 'A' }) } qr/Parameter failed check constraint/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 10, sex => 's' }) } qr/Parameter failed check constraint/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L' }) } qr/Missing required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => undef, age => 10 }) } qr/Undefined required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F' }) } qr/Missing required parameter/;
    throws_ok { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'X' })  } qr/Parameter failed check constraint/;
    lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'UK' }) };
    lives_ok  { $validator->validate('add_user', { firstname => 'F', lastname => 'L', age => 40, location => 'uk' }) };

    done_testing();

=head2 Hooking your own check method

It allows you to provide your own method for validating a field as shown below:

    use strict; use warnings;
    use Test::More;
    use Test::Exception;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new;

    my $LOCATION = { 'USA' => 1, 'UK' => 1 };
    sub lookup { exists $LOCATION->{uc($_[0])} };

    $validator->add_field({ name => 'location', format => 's', check => \&lookup });
    $validator->add_method({ name => 'check_location', fields => { location => 1 }});

    throws_ok { $validator->validate('check_location', { location => 'X' }) } qr/Parameter failed check constraint/;

    done_testing();

The above can be achieved using the configuration file as shown below:

    { "fields"  : [
                     { "name" : "location", "format" : "s", "source": [ "USA", "UK" ] }
                  ],
      "methods" : [
                     { "name"  : "check_location", "fields": { "location" : "1" } }
                  ]
    }

Using the above configuration file test the code as below:

    use strict; use warnings;
    use Test::More;
    use Test::Exception;
    use Method::ParamValidator;

    my $validator = Method::ParamValidator->new({ config => "config.json" });

    throws_ok { $validator->validate('check_location', { location => 'X' }) } qr/Parameter failed check constraint/;

    done_testing();

=head2 Plug-n-Play with Moo package

Lets start with a basic Moo package C<Calculator>.

    package Calculator;

    use Moo;
    use namespace::autoclean;

    sub do {
        my ($self, $param) = @_;

        if ($param->{op} eq 'add') {
           return ($param->{a} + $param->{b});
        }
        elsif ($param->{op} eq 'sub') {
           return ($param->{a} - $param->{b});
        }
        elsif ($param->{op} eq 'mul') {
           return ($param->{a} * $param->{b});
        }
    }

    1;

Now we need to create configuration file for the package C<Calculator> as below:

    { "fields"  : [ { "name" : "op", "format" : "s", "source": [ "add", "sub", "mul" ] },
                    { "name" : "a",  "format" : "d" },
                    { "name" : "b",  "format" : "d" }
                  ],
      "methods" : [ { "name"  : "do",
                      "fields": { "op" : "1",
                                  "a"  : "1",
                                  "b"  : "1"
                                }
                    }
                  ]
    }

Finally plug the validator to the package C<Calculator> as below:

    use Method::ParamValidator;

    has 'validator' => (
        is      => 'ro',
        default => sub { Method::ParamValidator->new(config => "config.json") }
    );

    before [qw/do/] => sub {
        my ($self, $param) = @_;

        my $method = (caller(1))[3];
        $method =~ /(.*)\:\:(.*)$/;
        $self->validator->validate($2, $param);
    };

Here is unit test for the package C<Calculator>.

    use strict; use warnings;
    use Test::More;
    use Test::Exception;
    use Calculator;

    my $calc = Calculator->new;

    is($calc->do({ op => 'add', a => 4, b => 2 }), 6);
    is($calc->do({ op => 'sub', a => 4, b => 2 }), 2);
    is($calc->do({ op => 'mul', a => 4, b => 2 }), 8);

    throws_ok { $calc->do({ op => 'add' }) } qr/Missing required parameter. \(a\)/;
    throws_ok { $calc->do({ op => 'add', a => 1 }) } qr/Missing required parameter. \(b\)/;
    throws_ok { $calc->do({ op => 'x', a => 1, b => 2 }) } qr/Parameter failed check constraint. \(op\)/;
    throws_ok { $calc->do({ op => 'add', a => 'x', b => 2 }) } qr/Parameter failed check constraint. \(a\)/;
    throws_ok { $calc->do({ op => 'add', a => 1, b => 'x' }) } qr/Parameter failed check constraint. \(b\)/;

    done_testing();

=cut

sub BUILD {
    my ($self) = @_;

    if ($self->has_config) {
        my $data = do {
            open (my $fh, "<:encoding(utf-8)", $self->config);
            local $/;
            <$fh>
        };

        my $config = JSON->new->decode($data);

        my ($fields);
        foreach (@{$config->{fields}}) {
           my $source = {};
           if (exists $_->{source}) {
               foreach my $v (@{$_->{source}}) {
                   $source->{uc($v)} = 1;
               }
           }

           $self->add_field({
               name   => $_->{name},
               format => $_->{format},
               source => $source,
               multi  => $_->{multi},
           });
        }

        foreach my $method (@{$config->{methods}}) {
            $self->add_method($method);
        }
    }
}

=head1 METHODS

=head2 validate($method_name, \%params)

Validates the given method C<$name> against the given parameters C<\%params>.
Throws exception if validation fail.

=cut

sub validate {
    my ($self, $key, $values) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingMethodName->throw({
        method   => 'validate',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $key);

    Method::ParamValidator::Exception::InvalidMethodName->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (exists $self->{methods}->{$key});

    Method::ParamValidator::Exception::MissingParameters->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $values);

    Method::ParamValidator::Exception::InvalidParameterDataStructure->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (ref($values) eq 'HASH');

    my $method = $self->get_method($key);
    my $fields = $method->get_fields;
    foreach my $field (@{$fields}) {
        my $field_name = $field->name;
        if ($method->is_required_field($field_name)) {
            Method::ParamValidator::Exception::MissingRequiredParameter->throw({
                method   => $key,
                field    => sprintf("(%s)", $field_name),
                filename => $caller[1],
                line     => $caller[2] }) unless (exists $values->{$field_name});
            Method::ParamValidator::Exception::UndefinedRequiredParameter->throw({
                method   => $key,
                field    => sprintf("(%s)", $field_name),
                filename => $caller[1],
                line     => $caller[2] }) unless (defined $values->{$field_name});
        }

        Method::ParamValidator::Exception::FailedParameterCheckConstraint->throw({
            method   => $key,
            field    => sprintf("(%s)", $field_name),
            filename => $caller[1],
            line     => $caller[2] })
            if (defined $values->{$field_name} && !$field->valid($values->{$field_name}));
    }
}

=head2 query_param($method, \%values)

Returns the query param for the given method C<$method> and C<\%values>.
Throws exception if validation fail.

=cut

sub query_param {
    my ($self, $key, $values) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingMethodName->throw({
        method   => 'query_param',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $key);

    Method::ParamValidator::Exception::InvalidMethodName->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (exists $self->{methods}->{$key});

    Method::ParamValidator::Exception::MissingParameters->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $values);

    Method::ParamValidator::Exception::InvalidParameterDataStructure->throw({
        method   => $key,
        filename => $caller[1],
        line     => $caller[2] }) unless (ref($values) eq 'HASH');

    my $method = $self->get_method($key);
    my $fields = $method->get_fields;
    my $query_param = '';
    foreach my $field (@{$fields}) {
        my $field_name = $field->name;
        my $_key = "&$field_name=%" . $field->format;
        $query_param .= sprintf($_key, $values->{$field_name}) if defined $values->{$field_name};
    }

    return $query_param;
}

=head2 add_field(\%param)

Add field to the validator. Parameters are defined as below:

    +---------+-----------------------------------------------------------------+
    | Key     | Description                                                     |
    +---------+-----------------------------------------------------------------+
    |         |                                                                 |
    | name    | Unique field name. Required.                                    |
    |         |                                                                 |
    | format  | Field data type. Optional, default is 's', other valid value    |
    |         | is 'd'.                                                         |
    |         |                                                                 |
    | check   | Optional code ref to validate field value.                      |
    |         |                                                                 |
    | source  | Optional hashref to validate field value against.               |
    |         |                                                                 |
    | message | Optional field message.                                         |
    |         |                                                                 |
    +---------+-----------------------------------------------------------------+

=cut

sub add_field {
    my ($self, $param) = @_;

    return if (exists $self->{fields}->{$param->{name}});

    $self->{fields}->{$param->{name}} = Method::ParamValidator::Key::Field->new($param);
}

=head2 get_field($name)

Returns an object of type L<Method::ParamValidator::Key::Field>, matching field name C<$name>.

=cut

sub get_field {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingFieldName->throw({
        method   => 'get_field',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $name);

    return $self->{fields}->{$name};
}

=head2 add_method(\%param)

Add method to the validator. Parameters are defined as below:

    +---------+-----------------------------------------------------------------+
    | Key     | Description                                                     |
    +---------+-----------------------------------------------------------------+
    |         |                                                                 |
    | name    | Method name.                                                    |
    |         |                                                                 |
    | fields  | Hash ref to list of fields e.g { field_1 => 1, field_2 => 0 }   |
    |         | field_1 is required and field_2 is optional.                    |
    |         |                                                                 |
    +---------+-----------------------------------------------------------------+

=cut

sub add_method {
    my ($self, $param) = @_;

    return if (exists $self->{methods}->{$param->{name}});

    my $method = { name => $param->{name} };
    foreach my $field (keys %{$param->{fields}}) {
        $method->{fields}->{$field}->{object}   = $self->{fields}->{$field};
        $method->{fields}->{$field}->{required} = $param->{fields}->{$field};
    }

    $self->{methods}->{$param->{name}} = Method::ParamValidator::Key::Method->new($method);
}

=head2 get_method($name)

Returns an object of type L<Method::ParamValidator::Key::Method>, matching method name C<$name>.

=cut

sub get_method {
    my ($self, $name) = @_;

    my @caller = caller(0);
    @caller = caller(2) if $caller[3] eq '(eval)';

    Method::ParamValidator::Exception::MissingMethodName->throw({
        method   => 'get_method',
        filename => $caller[1],
        line     => $caller[2] }) unless (defined $name);

    return $self->{methods}->{$name};
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Method-ParamValidator>

=head1 BUGS

Please report any  bugs or feature requests to C<bug-method-paramvalidator at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-ParamValidator>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::ParamValidator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-ParamValidator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-ParamValidator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Method-ParamValidator>

=item * Search CPAN

L<http://search.cpan.org/dist/Method-ParamValidator/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Method::ParamValidator
