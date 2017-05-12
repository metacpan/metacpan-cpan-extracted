package Git::Gitalist;

use Git::Gitalist::Repository;

$VERSION = '0.000003';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Gitalist - An interface to git influenced by Gitalist

=head1 SYNOPSIS

    use Git::Gitalist;
    my $repository = Git::Gitalist::Repository->new('some-repo/.git');
    $repository->name;        # 'Some-Repo'
    $repository->path;        # 'some-repo/.git'

=head1 SEE ALSO

This is just a convenience class for C<use> and distribution reasons,
the real docs are in the classes further down the namespace.

L<Git::Gitalist::Repository>

L<Git::Gitalist::Object::Commit>

=head1 AUTHORS AND COPYRIGHT

  © 2014 Dan Brook <dan@broquaint.com>

  Gitalist:
    © 2009 Venda Ltd and Dan Brook <broq@cpan.org>
    © 2009, Tom Doran <bobtfish@bobtfish.net>
    © 2009, Zac Stevens <zts@cryptocracy.com>

  gitweb.cgi components from which Gitalist was derived:
    © 2005-2006, Kay Sievers <kay.sievers@vrfy.org>
    © 2005, Christian Gierke

  Model based on http://github.com/rafl/gitweb
    © 2008, Florian Ragwitz

=head1 LICENSE

Licensed under GNU GPL v2

=cut
