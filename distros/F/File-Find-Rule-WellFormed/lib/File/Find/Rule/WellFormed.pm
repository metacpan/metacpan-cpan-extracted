package File::Find::Rule::WellFormed;

use strict;
use vars qw($VERSION);
use base qw(File::Find::Rule);

use File::Find::Rule;
use XML::Parser;

sub File::Find::Rule::wellformed () {
    my $self = shift->_force_object();

    $self->exec(sub { eval { XML::Parser->new->parsefile(shift) } });
}

1;

__END__

=head1 NAME

File::Find::Rule::WellFormed - Find well-formed XML documents

=head1 SYNOPSIS

    use File::Find::Rule qw(:WellFormed);

    my @files = find(wellformed => in => $ENV{HOME});

=head1 DESCRIPTION

C<File::Find::Rule::WellFormed> extends C<File::Find::Rule> to find
well-formed (or not well-formed) XML documents, by providing the 
C<wellformed> test:

  my @wellformed = File::Find::Rule->new
                                   ->file
                                   ->name('*.xml')
                                   ->wellformed
                                   ->in('/');

The C<wellformed> test can be reversed, per standard
C<File::Find::Rule> semantics:

  # OO
  my @malformed = File::Find::Rule->new
                                  ->file
                                  ->name('*.xml')
                                  ->not_wellformed
                                  ->in('/');

  # functional
  my @malformed = find('!wellformed' => in => '/');

C<wellformed> takes no arguments.

=head1 SEE ALSO

L<File::Find::Rule>, L<File::Find::Rule::Extending>, L<XML::Parser>

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>
