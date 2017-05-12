# NAME

Kossy::Validator - form validator

# SYNOPSIS

    use Kossy::Validator;
    

    my $req = Plack::Request->new($env);
    

    my $result = Kossy::Validator->check($req, [
          'q' => [['NOT_NULL','query must be defined']],
          'level' => {
              default => 'M', # or sub { 'M' }
              rule => [
                  [['CHOICE',qw/L M Q H/],'invalid level char'],
              ],
          },
          '@area' => {
              rule => [
                  ['UINT','area must be uint'],
                  [['CHOICE', (0..40)],'invalid area'],
              ],
          },
    ]);

    $result->has_error:Flag
    $result->messages:ArrayRef[`Str]

    my $val = $result->valid('q');
    my @val = $result->valid('area');

    my $hash = $result->valid:Hash::MultiValue;



# DESCRIPTION

minimalistic form validator used in [Kossy](http://search.cpan.org/perldoc?Kossy)

# VALIDATORS

- NOT\_NULL
- CHOICE

        ['CHOICE',qw/dog cat/]
- INT

    int

- UINT

    unsigned int

- NATURAL

    natural number

- REAL, DOUBLE, FLOAT

    floating number

- @SELECTED\_NUM

        ['@SELECTED_NUM',min,max]
- @SELECTED\_UNIQ

    all selected values are unique

# CODEref VALIDATOR

    my $result = Kossy::Validator->check($req,[
        'q' => [
            [sub{
                my ($req,$val) = @_;
            },'invalid']
        ],
    ]);
    

    my $result = Kossy::Validator->check($req,[
        'q' => [
            [[sub{
                my ($req,$val,@args) = @_;
            },0,1],'invalid']
        ],
    ]);

# ADDING VALIDATORS

add to %Kossy::Validator::VALIDATOR

    local $Kossy::Validator::VALIDATOR{MYRULE} = sub {
        my ($req, $val, @args) = @_;
        return 1;
    };

    local $Kossy::Validator::VALIDATOR{'@MYRULE2'} = sub {
        my ($req, $vals, $num) = @_;
        return if @$vals != $num;
        return if uniq(@$vals) == $num;
    };

    Kossy::Validator->check($req,[
        key1 => [['MYRULE','my rule']],
        '@key2' => {
           rule => [
               [['@MYRULE2',3], 'select 3 items'],
               [['CHOICE',qw/1 2 3 4 5/], 'invalid']
           ],
        }
    ]);

if rule name start with '@', all values are passed as ArrayRef instead of last value.

# SEE ALSO

[Kossy](http://search.cpan.org/perldoc?Kossy)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
