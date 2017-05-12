use strict;
use warnings;
package Email::FolderType;
{
  $Email::FolderType::VERSION = '0.814';
}
# ABSTRACT: Email::FolderType - determine the type of a mail folder
use Module::Pluggable search_path => "Email::FolderType",
                      require     => 1,
                      sub_name    => 'matchers';

use Exporter 5.57 'import';

our @EXPORT_OK = qw(folder_type);

our $DEFAULT = 'Mbox';


sub folder_type ($) {
    my $folder  = shift;
    my $package = __PACKAGE__;

    no strict 'refs';


    foreach my $class ($package->matchers) {
        my $type = $class;

        $type =~ s!^$package\:\:!!;

        next if $type eq $DEFAULT; # delay till later since it's the default

        my $return;
        eval {
            $return = &{"$class\::match"}($folder);
        };
        return $type if $return;

    }

    # default
    return $DEFAULT if &{"$package\::$DEFAULT\::match"}($folder);

    return undef;
}



1;

__END__

=pod

=head1 NAME

Email::FolderType - Email::FolderType - determine the type of a mail folder

=head1 VERSION

version 0.814

=head1 SYNOPSIS

  use Email::FolderType qw(folder_type);

  print folder_type "~/mymbox";     # prints 'Mbox'
  print folder_type "~/a_maildir/"; # prints 'Maildir'
  print folder_type "some_mh/.";    # prints 'MH'
  print folder_type "an_archive//"; # prints 'Ezmlm'

=head1 DESCRIPTION

Provides a utility subroutine for detecting the type of a given mail
folder.

=head1 SUBROUTINES

=head2 folder_type <path>

Automatically detects what type of mail folder the path refers to and
returns the name of that type.

It primarily bases the type on the suffix of the path given.

  Suffix | Type
 --------+---------
  /      | Maildir
  /.     | MH
  //     | Ezmlm

In case of no known suffix it checks for a known file structure.  If
that doesn't work out it defaults to C<Mbox> although, if the C<Mbox>
matcher has been overridden or the default changed (see B<DEFAULT MATCHER>
below) then it will return undef.

=head2 matchers

Returns a list of all the matchers available to the system.

=head1 DEFAULT MATCHER

Currently the default matcher is C<Mbox> and therefore it is always
checked last and always returns C<1>.

If you really want to change this then you should override C<Email::FolderType::Mbox::match>
and/or change the variable C<$Email::FolderType::DEFAULT> to be something other than C<'Mbox'>.

	use Email::FolderType;
	use Email::FolderType::Mbox;

	$Email::FolderType::DEFAULT = 'NewDefault';

    package Email::FolderType::Mbox;
    sub match { return (defined $_[0] && -f $_[0]) }

	package Email::FolderType::NewDefault;
	sub match { return (defined $_[0] && $_[0] =~ m!some crazy pattern!) }
	1;

=head1 REGISTERING NEW TYPES

C<Email::FolderType> briefly flirted with a rather clunky C<register_type>
method for registering new matchers but, in retrospect that wasn't a great
idea.

Instead, in this version we've reverted to a C<Module::Pluggable> based system -
any classes in the C<Email::FolderType::> namespace will be interrogated to see
if they have a c<match> method.

If they do then it will be passed the folder name. If the folder matches then
the match function should return C<1>. For example ...

    package Email::FolderType::GzippedMbox;

    sub match {
        my $folder = shift;
        return (-f $folder && $folder =~ /.gz$/);
    }

    1;

These can even be defined inline ...

    #!perl -w

    use strict;
    use Email::Folder;
    use Email::LocalDelivery;

    # copy all mail from an IMAP folder
    my $folder = Email::Folder->new('imap://example.com'); # read INBOX
    for ($folder->messages) {
        Email::LocalDelivery->deliver($_->as_string, 'local_mbox');
    }

    package Email::FolderType::IMAP;

    sub match {
        my $folder = shift;
        return $folder =~ m!^imap://!;
    }

    1;

If there is demand for a compatability shim for the old C<register_type>
method then we can implement one. Really though, this is much better in
the long run.

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Simon Wistow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
