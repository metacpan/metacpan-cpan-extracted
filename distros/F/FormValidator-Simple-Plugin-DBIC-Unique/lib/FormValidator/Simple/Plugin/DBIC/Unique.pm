package FormValidator::Simple::Plugin::DBIC::Unique;
use strict;
use warnings;
use UNIVERSAL;
use UNIVERSAL::require;
use Scalar::Util qw/blessed/;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;

our $VERSION = '0.05';

sub DBIC_UNIQUE {

    my ($class, $params, $args) = @_;

    unless ( scalar(@$args) >= 2 ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation DBIC_UNIQUE needs two arguments at least. /
        .qq/Set name of DBIC table class and unique column(s). /
        );
    }
    my $table = shift @$args;
    unless ( scalar(@$params) == scalar(@$args) ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation DBIC_UNIQUE: number of keys and validation arguments aren't same/
        );
    }
    unless ( blessed($table) and $table->can('count') ) {
        if ( $class->options->{dbic_base_class} ) {
            $table = $class->options->{dbic_base_class}."::".$table;
        }
        $table->require;
        if ($@) {
            FormValidator::Simple::Exception->throw(
                qq/Validation DBIC_UNIQUE: failed to require $table. "$@"/
            );
        }
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
    my $count = $table->count(\%criteria);
    return $count > 0 ? FALSE : TRUE;
}

1;
__END__

=head1 NAME

FormValidator::Simple::Plugin::DBIC::Unique - unique check for DBIC

=head1 SYNOPSIS

    use FormValidator::Simple qw/DBIC::Unique/;

    # check single column
    FormValidator::Simple->check( $q => [
        name => [ [qw/DBIC_UNIQUE TableClass name/] ],
    ] );

    # check multiple columns
    FormValidator::Simple->check( $q => [
        { unique => [qw/name email/] } => [ [qw/DBIC_UNIQUE TableClass name mail/] ],
    ] );

    # check multiple columns including '!=' check
    # set "!" as prefix for key-name
    FormValidator::Simple->check( $q => [
        { unique => [qw/id name email/] } => [ [qw/DBIC_UNIQUE Table !id name mail/] ]
    ] );


    # when the class name is too long...
    FormValidator::Simple->check( $q => [
        name => [ [qw/DBIC_UNIQUE MyProj::Model::User name/] ],
    ] );

    # you can set cdbi_base_class in option.
    FormValidator::Simple->set_option( dbic_base_class => 'MyProj::Model' );
    FormValidator::Simple->check( $q => [
        name => [ [qw/DBIC_UNIQUE User name/] ],
    ] );

    # you also can pass resultset object.

    # in catalyst application,
    FormValidator::Simple->check( $q => [
        name => [ ['DBIC_UNIQUE', $c->model('Schema::User'), 'username' ] ],
    ] );
    
    # in case you use schema,
    FormValidator::Simple->check( $q => [
        name => [ [ 'DBIC_UNIQUE', $c->model('Schema')->resultset('User'), 'username' ] ],
    ] );
    
    FormValidator::Simple->check( $q => [
        name => [ [ 'DBIC_UNIQUE', $schema->resultset('User'), 'username' ] ],
    ] );

=head1 DESCRIPTION

This module is a plugin for FormValidator::Simple. This provides you a validation for unique check with DBIC table class.

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

