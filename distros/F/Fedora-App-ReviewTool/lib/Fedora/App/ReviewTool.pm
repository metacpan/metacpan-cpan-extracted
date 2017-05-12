#############################################################################
#
# ReviewTool application class
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 09:17:06 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool;

use Moose;

use MooseX::Types::Path::Class ':all';

# all templates are kept in here.
use Data::Section -setup;
use Crypt::OpenSSL::X509;
use Path::Class;
use Template;

use namespace::clean -except => [ 'meta', 'section_data' ];

our $VERSION = '0.10';

extends qw{ MooseX::App::Cmd };

#############################################################################
# x509 cert bits (our fedora cert)

has cert_file => (is => 'ro', lazy_build => 1, isa => File, coerce => 1);
has cert      => (is => 'ro', lazy_build => 1, isa => 'Maybe[Crypt::OpenSSL::X509]');

has email => (is => 'ro', isa => 'Str', lazy_build => 1);
has cn    => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_cert_file { file $ENV{HOME}, '.fedora.cert' }

sub _build_cert      { 
    my $self = shift @_;
    
    # don't bother if file doesn't exist
    return undef unless $self->cert_file->stat;

    my $cert;
    eval { $cert = Crypt::OpenSSL::X509->new_from_file($self->cert_file) };

    return $cert unless $@;

    # if we make it this far, something wonky happened
    warn "Error looking at cert: $@\n";
    return undef;
}

sub _build_email { 
    my $self = shift @_;

    return $self->cert ?  $self->cert->email : 'nobody@fedoraproject.org';
}

sub _build_cn    { 
    my $self = shift @_;

    return 'nobody' unless $self->cert;

    my @cns = 
        map { s/^CN=//; s/,$//; $_} 
        grep { /^CN/ } 
        split /\s+/, $self->cert->subject
        ; 

    shift @cns;
}

#############################################################################
# common startup stuff

sub startup_checks {
    my $self = shift @_;

    #warn "here";

    die '$HOME is not set!' . "\n" unless exists $ENV{HOME};

    die "~/.fedora.cert does not exist!\n" 
        unless file($ENV{HOME}, '.fedora.cert')->stat;

    my @files = 
        map { file $ENV{HOME}, $_ } 
        qw{ .fedora-server-ca.cert .fedora-upload-ca.cert }
        ;

    for my $file (@files) {

        warn "$file does not exist; koji builds may be impacted!\n"
            unless $file->stat;
    }

    return;
}

#############################################################################
# template bits

has _tt2 => (is => 'ro', isa => 'Template', lazy_build => 1);
sub _build__tt2 { Template->new() }

sub _from_template {
    my $self = shift @_;
    my $tmpl = shift @_;
    my %args = @_;

    my $ret;

    $self->_tt2->process(
        $self->section_data($tmpl),
        \%args,
        \$ret,
    );

    return $ret;
}

# template shortcuts
sub verbose_description { shift->_from_template('verbose_description', @_) }
sub branch              { shift->_from_template('branch', @_)              }
sub update              { shift->_from_template('update', @_)              }
sub new_tix             { shift->_from_template('new_tix', @_)             }
sub verbose_submit      { shift->_from_template('verbose_submit', @_)      }
sub import_task_review  { shift->_from_template('import_task_review', @_)  }

1;

__DATA__
__[ review ]__

TEST REVIEW TEMPLATE

- comments here -

koji: [% koji_url %]

NOTE: License auto-detection only works for perl, and not even there yet.

Spec looks sane, clean and consistent; license is correct ([% license %]);
make test passes cleanly.

Source tarballs match upstream (sha1sum):
[% FOREACH pkg = sha1sum.keys.sort -%]
[% sha1sum.$pkg %] [% pkg %]
[% END -%]

Final provides / requires are sane:

[% rpmcheck %]
__[ update ]__
Spec URL: [% spec %]
SRPM URL: [% srpm %]

[% IF koji -%]
Koji build: [% koji %]
[% END -%]
__[ new_tix ]__
Spec URL: [% spec %]
SRPM URL: [% srpm %]

Description:
[% description -%]

[% IF koji -%]

Koji build: [% koji %]
[% END -%]
[% IF additional_comment -%]

Additional Comment:

[% additional_comment %]
[% END -%]

*rt-[% version -%]
__[ branch ]__
New Package CVS Request
=======================
Package Name: [% name %]
Short Description: [% summary %]
Owners: [% owners %]
Branches: [% branches %]
InitialCC: [% cc %]
__[ verbose_description ]__
#!#!#!#!#!#!#!#!#!!#!#!!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
Bug:      [% bug.id          %]
Summary:  [% bug.summary     %]
Status:   [% bug.status      %]
Assignee: [% bug.assigned_to %]

Last comment:

// Begin comment //////////////////////////////////////////////////////
[% bug.last_comment %]
// End comment ////////////////////////////////////////////////////////

Branch request:

// Begin /////////////////////////////////////////////
[% branch_req -%]
// End ///////////////////////////////////////////////
__[ verbose_submit ]__
#!#!#!#!#!#!#!#!#!!#!#!!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
Pkg:      [% bug.name          %]
Summary:  [% bug.summary       %]
SRPM:     [% bug.srpm.basename %]

// Begin tix body ////////////////////////////////////////////////////
[% body %]
// End tix body //////////////////////////////////////////////////////

__[ import_task_review ]__

// Task Review ///////////////////////////////////////////////////////

[% FOREACH job = jobs -%]
    [% job %]
[% END -%]

There are [% jobs.size %] jobs total, and will be executed 3 at a time.

__[ pod ]__

=head1 NAME

Fedora::App::ReviewTool - Application class for ReviewTool

=head1 SYNOPSIS

    # in your script...
    use Fedora::App::ReviewTool;

    Fedora::App::ReviewTool->run;

=head1 DESCRIPTION

B<THIS CODE IS STILL UNDER MAJOR FLUX; YMMV!>

Application class for ReviewTool.  We don't do much except extend the 
base (L<MooseX::App::Cmd>) and provide a common place to keep our templates
(a la L<Data::Section>).

=head1 METHODS 

=head2 data_section()

Returns a reference to the named data section (in our case, typically
templates).

=head2 meta()

Access to our metaclass.

=head1 SEE ALSO

L<Data::Section>, L<MooseX::App::Cmd>, L<App::Cmd>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Chris Weyl <cweyl@alumni.drew.edu>, or (preferred) 
to this package's RT tracker at E<bug-PACKAGE@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



