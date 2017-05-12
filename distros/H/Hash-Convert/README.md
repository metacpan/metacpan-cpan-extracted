# NAME

Hash::Convert - Rule based Hash converter.

# SYNOPSIS

    #!/usr/bin/env perl
    use strict;
    use warnings;
    use Hash::Convert;

    my $rules = {
        visit   => { from => 'created_at' },
        count   => { from => 'count', via => sub { $_[0] + 1 }, default => 1 },
        visitor => {
            contain => {
                name => { from => 'name' },
                mail => { from => 'mail' },
            },
            default => {
                name => 'anonymous',
                mail => 'anonymous',
            }
        },
        price => {
            from => [qw/item.cost item.discount/],
            via => sub {
                my $cost     = $_[0];
                my $discount = $_[1];
                return $cost * ( (100 - $discount) * 0.01 );
            },
        },
    };
    my $opts = { pass => 'locate' };

    my $converter = Hash::Convert->new($rules, $opts);

    my $before = {
        created_at => time,
        count      => 1,
        name       => 'hixi',
        mail       => 'hixi@cpan.org',
        locate     => 'JP',
        item => {
            name     => 'chocolate',
            cost     => 100,
            discount => 10,
        },
    };
    my $after = $converter->convert($before);
    print Dumper $after;
    #{
    #    'visitor' => {
    #        'mail' => 'hixi@cpan.org',
    #        'name' => 'hixi'
    #    },
    #    'count' => 2,
    #    'visit' => '1377019766',
    #    'price' => 90,
    #    'locate' => 'JP'
    #}

# DESCRIPTION

Hash::Convert is can define hash converter based on the rules.

# Function

## convert

Convert hash structure from before value.

    my $rules = {
        mail => { from => 'email' }
    };
    my $converter = Hash::Convert->new($rules);
    my $before = { email => 'hixi@cpan.org' };
    my $after  = $converter->convert($before);
    #{
    #  mail => 'hixi@cpan.org',
    #}

# Rules

## Command

- from

        my $rules = { visit => { from => 'created_at' } };
        #(
        #(exists $before->{created_at})?
        #    (visit => $before->{created_at}): (),
        #)
- from + via

    \`via\` add after method toward \`from\`.
    \`via\` can receive multiple args from \`from\`.

    Single args

        my $rules = { version => { from => 'version', via => sub { $_[0] + 1 } } };
        #(
        #(exists $before->{version})?
        #    (version => sub {
        #        $_[0] + 1;
        #    }->($before->{version})): (),
        #)

    Multi args

        my $rules = { price => {
            from => [qw/cost discount/],
            via => sub {
                my $cost     = $_[0];
                my $discount = $_[1];
                return $cost * (100 - $discount);
        }};
        #(
        #(exists $before->{item}->{cost} && exists $before->{item}->{discount})?
        #    (price => sub {
        #        my $cost = $_[0];
        #        my $discount = $_[1];
        #        return $cost * (100 - $discount);
        #    }->($before->{item}->{cost}, $before->{item}->{discount})): (),
        #)

- contain

        my $rules = { visitor => {
            contain => {
                name => { from => 'name' },
                mail => { from => 'mail' },
            }
        }};
        #(
        #(exists $before->{name} && exists $before->{mail})?
        #    (visitor => {
        #    (exists $before->{mail})?
        #        (mail => $before->{mail}): (),
        #    (exists $before->{name})?
        #        (name => $before->{name}): (),
        #    }): (),
        #)

## Others expression

- default

    default can add all command (\`from\`, \`from\`+\`via\`, \`contain\`) .

        my $rules = { visitor => {
            contain => {
                name => { from => 'name' },
                mail => { from => 'mail' },
            },
            default => {
                name => 'anonymous',
                mail => 'anonymous',
            }
        }};
        #(
        #(visitor => {
        #(exists $before->{mail})?
        #    (mail => $before->{mail}): (),
        #(exists $before->{name})?
        #    (name => $before->{name}): (),
        #}):
        #(visitor => {
        #  'name' => 'anonymous',
        #  'mail' => 'anonymous'
        #}),
        #)

- dot notation

    \`dot notation\` make available nested hash structure.

        my $rules = { price => {
            from => [qw/item.cost item.discount/],
            via => sub {
                my $cost     = $_[0];
                my $discount = $_[1];
                return $cost * ( (100 - $discount) * 0.01 );
            },
        }};
        #(
        #(exists $before->{item}->{cost} && exists $before->{item}->{discount})?
        #    (price => sub {
        #        my $cost = $_[0];
        #        my $discount = $_[1];
        #        return $cost * ( (100 - $discount) * 0.01 );
        #    }->($before->{item}->{cost}, $before->{item}->{discount})): (),
        #)



# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <hixi@cpan.org>
