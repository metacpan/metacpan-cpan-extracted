# $Id$
package Handel::Schema::RDBO::Object;
use strict;
use warnings;

BEGIN {
    use base qw/Rose::DB::Object/;
    use Handel::Schema::RDBO::DB;
};

sub init_db {
    my $class = shift;

    no strict 'refs';
    if (! ${"$class\:\:DB"}) {
        ${"$class\:\:DB"} = Handel::Schema::RDBO::DB->get_db;
    };

    return ${"$class\:\:DB"};
};

1;
__END__

=head1 NAME

Handel::Schema::RDBO::Object - Base object classes for Handel::Schema::RDBO classes

=head1 SYNOPSIS

    use Handel::Schema::RDBO::Cart;
    use strict;
    use warnings;
    
    BEGIN {
        use base qw/Handel::Schema::RDBO::Object/;
    };

=head1 DESCRIPTION

Handel::Schema::RDBO::DB is a generic Rose::DB class for use as the default
connections used in Handel::Storage::RDBO classes.

=head1 METHODS

=head2 init_db

Returns a new pre configured db object from Handel::Schema::RDBO::DB.

=head1 SEE ALSO

L<Handel::Schema::RDBO::DB>, L<Rose::DB>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

