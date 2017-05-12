package Locale::Scope;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.03";

use parent qw/Exporter/;
our @EXPORT_OK = qw/locale_scope/;

use POSIX qw/setlocale/;

sub locale_scope { __PACKAGE__->new(@_) }

sub new {
    my ($class, $category, $locale) = @_;
    return bless +{
        category => $category,
        before   => setlocale($category),
        current  => setlocale($category, $locale) || die "failed to setlocale. locale: $locale",
    } => $class;
}

sub DESTROY {
    my $self = shift;
    setlocale($self->{category}, $self->{before});
}

1;
__END__

=encoding utf-8

=head1 NAME

Locale::Scope - scope based setlocale(3)

=head1 SYNOPSIS

    use POSIX qw/LC_TIME/;
    use Locale::Scope qw/locale_scope/;

    # hear LC_TIME locale is C!!
    {
        my $scope = locale_scope(LC_TIME, "ja_JP.UTF-8");
        # hear LC_TIME locale is ja_JP.UTF-8!!
        {
            my $scope = locale_scope(LC_TIME, "es_AR.ISO8859-1");
            # hear LC_TIME locale is es_AR.ISO8859-1!!
        }
        # hear LC_TIME locale is ja_JP.UTF-8!!
    }
    # hear LC_TIME locale is C!!


=head1 DESCRIPTION

B<THE SOFTWARE IS IT'S IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

Locale::Scope is scope based L<setlocale(3)> for rollback locale at the end of a scope.

=head1 FUNCTION

=over

=item $scope = locale_scope($category, $locale);

Set the program's current locale.
It creates a new Locale::Scope object which rollbacks locale when its DESTROY method is called.

    my $scope = locale_scope($category, $locale);

    # or

    my $scope = Locale::Scope->new($category, $locale);

=back

=head1 SEE ALSO

L<POSIX>
L<Scope::Guard>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

