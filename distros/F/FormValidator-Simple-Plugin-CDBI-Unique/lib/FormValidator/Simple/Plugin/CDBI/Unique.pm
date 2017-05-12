package FormValidator::Simple::Plugin::CDBI::Unique;
use strict;
use warnings;
use UNIVERSAL;
use UNIVERSAL::require;
use SQL::Abstract;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;

our $VERSION = '0.03';

sub CDBI_UNIQUE {

    my ($class, $params, $args) = @_;

    unless ( scalar(@$args) >= 2 ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE needs two arguments at least. /
        .qq/Set name of CDBI table class and unique column(s). /
        );
    }

    my $table = shift @$args;
    unless ( scalar(@$params) == scalar(@$args) ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE: number of keys and validation arguments aren't same./
        );
    }
    if ( $class->options->{cdbi_base_class} ) {
        $table = $class->options->{cdbi_base_class}."::".$table;
    }
    $table->require;
    if ($@) {
        FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE: faild to require $table. "$@"/
        );
    }
    unless ( UNIVERSAL::isa( $table => 'Class::DBI' ) ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE: set CDBI table class as first argument./
        );
    }
    my %criteria = ();
    for ( my $i = 0; $i < scalar(@$args); $i++ ) {
        my $key   = $args->[$i];
        my $value = $params->[$i];
        if ( $key =~ /^!(.+)$/ ) {
            $criteria{$1} = { '!=' => $value };
        }
        else {
            $criteria{$key} = $value || '';
        }
    }
    foreach my $column ( keys %criteria ) {
        $table->find_column($column)
        or FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE: $column is not a column of $table./
        );
    }
    my($stmt, @bind) =
        SQL::Abstract->new->select($table->table, "COUNT(*)", \%criteria);

    my $count;
    eval{
        my $sth = $table->db_Main->prepare($stmt);
        $sth->execute(@bind);
        $sth->bind_columns(\$count);
        $sth->fetch;
    };
    if($@){
        FormValidator::Simple::Exception->throw(
        qq/Validation CDBI_UNIQUE: "$@"./
        );
    }
    return $count > 0 ? FALSE : TRUE;
}

1;
__END__

=head1 NAME

FormValidator::Simple::Plugin::CDBI::Unique - unique check for CDBI

=head1 SYNOPSIS

    use FormValidator::Simple qw/CDBI::Unique/;

    # check single column
    FormValidator::Simple->check( $q => [
        name => [ [qw/CDBI_UNIQUE TableClass name/] ],
    ] );

    # check multiple columns
    FormValidator::Simple->check( $q => [
        { unique => [qw/name email/] } => [ [qw/CDBI_UNIQUE TableClass name mail/] ],
    ] );

    # check multiple columns including '!=' check
    # set "!" as prefix for key-name
    FormValidator::Simple->check( $q => [
        { unique => [qw/id name email/] } => [ [qw/CDBI_UNIQUE Table !id name mail/] ]
    ] );


    # when the class name is too long...
    FormValidator::Simple->check( $q => [
        name => [ [qw/CDBI_UNIQUE MyProj::Model::User name/] ],
    ] );

    # you can set cdbi_base_class in option.
    FormValidator::Simple->set_option( cdbi_base_class => 'MyProj::Model' );
    FormValidator::Simple->check( $q => [
        name => [ [qw/CDBI_UNIQUE User name/] ],
    ] );

=head1 DESCRIPTION

This module is a plugin for FormValidator::Simple. This provides you a validation for unique check with CDBI table class.

=head1 SEE ALSO

L<FormValidator::Simple>

=head1 AUTHOR

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

Basic Idea: Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Lyo Kato

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

