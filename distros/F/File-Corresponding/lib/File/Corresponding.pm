
=head1 NAME

File::Corresponding - Find corresponding files in the directory tree



=head1 PREAMBLE

In a source tree it is common to have files with the same name, but in
different places in the directory tree. A typical MVC application
could look something like this:

 Book       lib/Controller/Book.pm
 Borrower   lib/Controller/Borrower.pm
 Book       lib/Model/Schema/Book.pm
 Borrower   lib/Model/Schema/Borrower.pm
 Book       lib/root/templates/Book.t
 Borrower   lib/root/templates/Borrower.t
 Book       lib/t/controller-book.t
 Borrower   lib/t/controller-borrower.t
 Book       lib/t/model-schema-book.t
 Borrower   lib/t/model-schema-borrower.t

Here we clearly have two types of things; a Book and a Borrower.

The C<Controller/Book.pm>, C<Model/Schema/Book.pm>,
C<root/templates/Book.t>, C<t/controller-book.t>, and
C<t/model-schema-book.t> represent different aspects of the same Book
entity; they I<correspond> to each other.

Since the files belong to each other it is useful for the programmer
to easily navigate between them.

This module helps with that.



=head1 SYNOPSIS

=head2 Config file

Given a config file C<.corresponding_file> in the current directory or
your $HOME directory:

  ---
  file_groups:
    -
      name: All MyApp classes
      file_profiles:
        -
          name: Cat Controller
          regex: / Controller . (\w+) \.pm $ /x
          sprintf: Controller/%s.pm
        -
          name: DBIC Schema
          regex: "|Model/Schema.(\w+)\.pm$|"
          sprintf: Model/Schema/%s.pm
        -
          name: Template
          regex: /root.template.(\w+)\.pm$/
          sprintf: root/template/%s.pm


=head2 From the command line

  $ corresponding_file Controller/Book.pm
  Model/Schema/Book.pm
  $ cd ..
  $ corresponding_file lib/Controller/Book.pm
  lib/Model/Schema/Book.pm


=head2 From your editor

=over 2

=item Emacs

L<Devel::PerlySense> has a feature "Go to Project's Other Files" for
navigating to related files.

Actually, it doesn't yet. But it will.

=back


=head2 From your program

By using C<File::Corresponding> as a library, you can use the
resulting L<File::Corresponding::File::Found> objects to display more
information than just the file name.



=head1 DESCRIPTION

C<File::Corresponding> uses a configuration of groups of File Profiles to
identify corresponding files.

Using a C<.corresponding_file> config file, and the command line
script C<corresponding_file>, you can easily look up corresponding
files.

It's obviously better if you let your editor do the tedious bits for
you, like passing the file name to the script, letting you choose
which of the corresponding files you meant, and opening the file in
the editor.

That's left as an exercise for the reader (well you I<are> a
programmer, aren't you?).



=head1 THE CONFIG FORMAT

Study the SYNOPSIS example.

A File Profile for e.g. "Controller" files includes a C<regex> to
match a Controller file name with e.g. "Book" in it, and a C<sprintf>
string template to render any found files with "Book" in them as a
Controller file.

Regex definitions are whatever comes after "qr" in
e.g. C<qr/file.pm/i>, i.e. "/file.pm/i". As you can see, you can use
regex modifiers, and even use other delimiters (which is handy, since
you're likely to match "/").

The C<regex> should match the intended file. The first capturing
parenthesis must contain the entity file fragmen that is common to all
files in the group.

The C<sprintf> string should contain a C<%s> to fill in the captured
file fragment from any other File Profile in the Group.

Only existing files are reported.



=head1 SEE ALSO



=head1 AUTHOR

Johan Lindstrom, C<< <johanl[AT]cpan.org> >>



=head1 BUGS AND CAVEATS

=head2 BUG REPORTS

Please report any bugs or feature requests to
C<bug-file-corresponding@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Corresponding>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head2 CAVEATS

Currently C<File::Corresponding> supports the simple case in the
SYNOPSIS above, where the Controller/Book.pm can easily be translated
to Model/Schema/Book.pm. It does not yet support the more complicated
translation from Controller/Book.pm to t/controller-book.t and back.


=head2 KNOWN BUGS


=head1 COPYRIGHT & LICENSE

Copyright 2007- Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.



=head1 *** DEVELOPER API DOCS ***

=head1 ERROR HANDLING MODEL

Failures will result in a die.



=cut

package File::Corresponding;
$File::Corresponding::VERSION = '0.004';
use Moose;



use Moose::Autobox;
use YAML::Tiny;
use Data::Dumper;

use File::Corresponding::Group;


=head1 ATTRIBUTES

=head2 profile_groups : ArrayRef[File::Corresponding::Group]

Group config objects.

=cut
has profile_groups => (
    is => "rw",
    isa => "ArrayRef[File::Corresponding::Group]",
    default => sub { [] },
);



=head1 METHODS

=head2 corresponding($file) : ArrayRef[File::Corresponding::File::Found]

Find files corresponding to $file (given the config in ->profile_groups)
and return found @files.

If the same file is found via many Groups, it will be reported once
per group (so if you only use this to display the file name, make sure
to unique the file names).

=cut
sub corresponding {
    my $self = shift;
    my ($file) = @_;

    my $found_files = $self->profile_groups ->map(sub { $_->corresponding($file)->flatten });

    return $found_files;
}



=head2 load_config_file($config_file) : 1

Load yaml $config_file, or die with an error message.

=cut
sub load_config_file {
    my $self = shift;
    my ($file) = @_;

    my $yaml = YAML::Tiny->read($file)
            or die("Could not read config file ($file):\n" . YAML::Tiny->errstr);
    my $config = $yaml->[0];

    my $die = sub {
        my $element = shift;
        die("Missing element '$element' in config file ($file)\n" . Dumper($config));
    };

    my $file_groups = $config->{file_groups} or $die->("file_groups");

    $self->profile_groups(
        $file_groups->map( sub {
            my $group = $_;
            my $name = $group->{name} || "";

            my $file_profiles = $group->{file_profiles} or $die->("file_profiles");
            my $profiles = $file_profiles->map( sub {
                File::Corresponding::File::Profile->new($_),
            });

            File::Corresponding::Group->new({
                name          => $name,
                file_profiles => $profiles,
            });
        }),
    );


    #print Dumper($config); use Data::Dumper;



    return 1;
}



1;



__END__
