package Filter::Arguments;

our $VERSION = '0.14';

use 5.0071;
use strict;
use warnings FATAL => 'all';
use Filter::Simple;

my @Identifiers;
my %Default_For;
my %Alias_For;

my $Retro_Arguments_Regex = qr{
    : \s* Arguments? \s*
    (?: [\(] .*? [\)] \s* )?
    ( = \s* [^;]+ )? ;
}msx;

my $Arguments_Regex = qr{
    ( [\@\$\%] \S+ \s* =  \s* )?
    Arguments? \s*
    ( [\(] .*? [\)] \s* )?
    (?= [,;\)\}\]] )
}msx;

my $Arguments_Usage_Regex = qr{
    Arguments?::verify_usage \s* (?: [\(] [\)] )?
}msx;

sub verify_usage {
    my $argv_ra = shift @_;
    my %arguments = @_;

    my $usage = "$0\n";
    my @errors;

    while ( my ($arg,$val) = each %arguments) {

        my $alias   = $Alias_For{$arg};
        my $default = $Default_For{$arg};

        $val ||= $default;

        if ( !defined $val ) {
            push @errors, "no value supplied for $arg";
        }

        $usage .= "  $alias";
        if ( defined $default ) {
            if ( length $default ) {
                $usage .= "\t(default is '$default')";
            }
            else {
                $usage .= "\t(default is empty string)";
            }
        }
        $usage .= "\n";
    }

    my %valid_alias = map { ( $Alias_For{$_} => 1 ) } keys %Alias_For;

    ARG:
    for my $arg (@{ $argv_ra }) {

        next ARG
            if $arg !~ m/\A --? /xms;

        if ( !defined $valid_alias{$arg} ) {

            if ( $arg =~ m{\A --? (?: help|usage|[?] ) \z}xms ) {
                push @errors, "Usage:";
            }
            else {
                push @errors, "unexpected argument $arg";
            }
        }
    }

    if ( @errors ) {

        for my $error (@errors) {
            warn "$error\n";
        }
        die "$usage\n";
    }
    return 1;
}

sub parse {
    my ( $identifier, $params_rh, $argv_ra ) = @_;

    $identifier =~ s{ (?: \A [\(]? \s* | \s* [\)]? ) }{}xmsg;

    if ( $identifier =~ m{,} ) {

        my @idents = split /\s*,\s*/, $identifier;
        my @results;
        for my $i ( 0 .. $#idents ) {

            my $ident  = $idents[$i];
            my %params = %{ $params_rh };

            if ( defined $params{default} && ref $params{default} eq 'ARRAY' ) {

                if ( $i <= $#{ $params{default} } ) {

                    $params{default} = $params{default}->[$i];
                }
                else {

                    delete $params{default};
                }
            }

            push @results, parse( $ident, \%params, $argv_ra );
        }
        return @results;
    }

    my ($sigil,$ident) = $identifier =~ m/\A ( \W+ ) ( \w+ ) \z/xms;
    $sigil ||= "";
    $ident ||= "";

    my $type
        = $sigil eq '@'            ? 'ARRAY'
        : $sigil eq '%'            ? 'HASH'
        : $ident =~ m/ _ra \z/xmsi ? 'ARRAY'
        : $ident =~ m/ _rh \z/xmsi ? 'HASH'
        :                            'SCALAR';

    my ($default,$alias);

    if ( $params_rh ) {

        if ( ref $params_rh eq 'HASH' ) {

            if ( defined $params_rh->{alias} ) {
                $alias = $params_rh->{alias};
            }

            if ( defined $params_rh->{default} ) {
                $default = $params_rh->{default};
            }

            if ( !$alias && !$default ) {

                ALIAS_DEFAULT:
                while ( my ($a,$d) = each %{ $params_rh } ) {

                    # Don't allow certain reserved words in this mode
                    # use: alias => 'default' when option --default is needed
                    # use: alias => 'alias' when option --alias is needed
                    next ALIAS_DEFAULT
                        if $a eq 'default' || $a eq 'alias';

                    ($alias,$default) = ($a,$d);
                }
            }
        }
    }

    $alias ||= $ident;
    $alias =~ s{ _r[ah] \z}{}xmsi;
    $alias = "--$alias";
    $alias =~ s{\A -{3,} }{--}xms;

    $Alias_For{$ident}   = $alias;
    $Default_For{$ident} = $default;

    if ( $type eq 'HASH' ) {

        my $key;
        my %arguments;

        ARG:
        for my $arg_index ( 0 .. $#{ $argv_ra } ) {

            my $arg = $argv_ra->[$arg_index];

            if ( $arg =~ m/\A --? /xms ) {

                $key = $arg;
                $key =~ s{\A [-]+ }{}xms;

                $arguments{$key} = [];
                next ARG;
            }
            else {

                if ( !$key ) {
                    $key = $alias;
                    $key =~ s{\A [-]+ }{}xms;
                }

                push @{ $arguments{$key} }, $arg;
            }
        }

        if ( !keys %arguments && $default ) {
            $key = $alias;
            $key =~ s{\A [-]+ }{}xms;
            $arguments{$key} = [ $default ];
        }

        for my $option (keys %arguments) {

            if ( @{ $arguments{$option} } == 0 ) {
                $arguments{$option} = 1;
            }
            elsif ( @{ $arguments{$option} } == 1 ) {
                $arguments{$option} = $arguments{$option}->[0];
            }
        }

        return %arguments
            if wantarray;

        return \%arguments;
    }

    ARG:
    for my $arg_index ( 0 .. $#{ $argv_ra } ) {

        my $next_index
            = $arg_index < $#{ $argv_ra }
            ? $arg_index + 1
            : undef;

        my $arg = $argv_ra->[$arg_index];

        next ARG
            if $arg ne $alias;

        if ( $type eq 'SCALAR' ) {

            my $value
                = defined $next_index
                ? $argv_ra->[$next_index]
                : 1;

            if ( $value =~ m/\A --? /xms ) {
                $value = $default || 1;
            }

            return $value;
        }
        elsif ( $type eq 'ARRAY' ) {

            my @values;

            VAL:
            for my $next_index ( $arg_index + 1 .. $#{ $argv_ra } ) {

                my $value = $argv_ra->[$next_index];

                last VAL
                    if $value =~ m/\A --? /xms;

                push @values, $value;
            }

            return @values
                if wantarray;

            return \@values;
        }
    }

    return @{ $default }
        if wantarray && $default && ref $default eq 'ARRAY';

    return $default;
}

sub retro_transform {
    my ($default) = @_;

    $default ||= "";

    if ( $default ) {

        $default =~ s{(?: \A [=\s]* | \s* \z )}{}xmsg;

        if ( $default =~ m{\A [\(] }xms ) {

            $default =~ s{(?: \A [\(] | \W \z )}{}xmsg;

            $default = "( default => [ $default ] )";
        }
        else {

            $default = "( default => '$default' )";
        }
    }

    return "= Arguments$default;";
}

sub transform {
    my ($assignment,$parameters) = @_;

    $assignment ||= "";
    $parameters ||= "";

    my $identifiers = $assignment;
    $identifiers =~ s{(?: \A \s* [^\@\$\%\(]* | \W* \z )}{}xmsg;
    $identifiers =~ s{\s*}{}xmsg;

    push @Identifiers, split /\s*,\s*/, $identifiers;

    return "${assignment}Filter::Arguments::parse(q{$identifiers},{$parameters},\\\@ARGV)";
}

sub usage {

    my $arg_string = "";

    for my $identifier (@Identifiers) {

        my $key = $identifier;
        my $val = $identifier;

        $key =~ s{\A \W }{}xmsg;

        $arg_string .= " $key => $val,";
    }

    return "Filter::Arguments::verify_usage(\\\@ARGV,$arg_string)";
}

FILTER_ONLY
	code_no_comments => sub {

        # for backward compatibility
        $_ =~ s{$Retro_Arguments_Regex}{retro_transform($1)}xmsge;

        $_ =~ s{$Arguments_Regex}{transform($1,$2)}xmsge;

        $_ =~ s{$Arguments_Usage_Regex}{usage()}xmsge;
	};

1;

__END__

=pod

=head1 NAME

Filter::Arguments - Configure and read your command line arguments from @ARGV.

=head1 SYNOPSIS

 use Filter::Arguments;

 @ARGV = qw( --drink Jolt --sandwhich BLT );

 my $beverage = Argument( alias => 'drink', default => 'tea' );
 my $food     = Argument( sandwich => 'ham & cheese' );

 Arguments::verify_usage();

 # prints "I'll have a BLT and a Jolt please."
 print "I'll have a $food and a $beverage please.\n";

=head1 DESCRIPTION

Here is a simple way to configure and parse your command line arguments from @ARGV.

=head1 FEATURES

=over

=item * Automatic enforcement of required values

=item * Automatic generation of usage text

=item * Automatic detection of alias

=item * Automatic construction of hash, array, scalar, hash ref, or array ref results

=back

=head1 EXAMPLES

=over

=item a required command line option

 my $beverage = Argument;
 Arguments::verify_usage();

If the --beverage option is not found in @ARGV then the verify_usage function will die with the appropriate usage instructions.

=item an optional command line option

 my $beverage = Argument( default => 'Milk' );
 Arguments::verify_usage();

If no --beverage option is found then the value 'Milk' is provided.

=item an aliased option populates a variable of a different name

 my $beverage = Argument( alias => 'drink' );
 Arguments::verify_usage();

The value of $beverage will be whatever is found to follow --drink in @ARGV.

=item an implied alias and default

 my $beverage = Argument( drink => 'Milk' );
 Arguments::verify_usage();

The value of $beverage will be whatever is found to follow --drink in @ARGV, or it will default to 'Milk'.

=item populate an array

 my @drinks = Argument( default => [qw( Water OJ Jolt )] );

The @drinks array will contain whatever values follow --drinks in @ARGV, or it will contain the given defaults.

=item populate a list of scalars

 my ($a,$b,$c) = Arguments;

This will populate $a, $b, and $c with 1 if --a, --b, and --c are all found in @ARGV.

Note, it sure would confuse matters if these variables are not booleans, or single value options.

=item slurp up everything in @ARGV as a hash

 my %args = Arguments;

Um, what exactly does that do?

 @ARGV = qw( --a --b --c --drink Jolt --eat Rice Beans --numbers 3 2 1 );

Translates to:

 %args = (
    a       => 1,
    b       => 1,
    c       => 1,
    drink   => 'Jolt',
    eat     => [ 'Rice', 'Beans' ],
    numbers => [ 3, 2, 1 ],
 )

Note, it wouldn't make much sense to use the verify_usage fuction in this case.

=item populate an array ref

 my $drinks_ra = Argument( default => [qw( Water OJ Jolt )] );

In this case the '_ra' naming convention for "reference to array" is noticed and the behavior is otherwise the same as the @drinks example above.

Note, the same example like this:

 my $drinks = Argument( default => [qw( Water OJ Jolt )] );

Now drinks is not recognized as a reference to array type of scalar, and instead it will be populated with 'Water'.

=item populate a hash ref

 my $args_rh = Arguments;

Same as the above example, where the '_rh' suffix is recognized as a special reference to hash and populated as such.

=back

=head1 DEPENDENCIES

=over

=item Filter::Simple

=back

=head1 TODO

=over

=item Regex or list based validation of given values.

For example:

 my $x = Argument( valid => qr{\A \d+ \z}xms );
 my $y = Argument( valid => [qw( 1 3 5 7 11 12 )] );

=item Usage validation without the need for a special function call.

=back

=head1 LIMITATIONS

Suppose you want to support the option --alias with a default value of 'default'.

 my $option = Argument( alias => 'default' );

This will be correctly interpreted as option --default and no default value.

This is a special case limitation because 'alias' is a reserved key.

In this one wierd particular situation you'll need to do:

 my $option = Argument( alias => 'alias', default => 'default' );

Or:

 my $alias = Argument( default => 'default' );

=head1 BUGS

Version 0.10 is a complete rewrite from 0.07.
Despite big improvements, this revision doesn't quite acheive the elegance I have always dreamed of.
I'm ready for anything.

=head1 AUTHOR

Dylan Doxey E<lt>dylan.doxey@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Dylan Doxey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
