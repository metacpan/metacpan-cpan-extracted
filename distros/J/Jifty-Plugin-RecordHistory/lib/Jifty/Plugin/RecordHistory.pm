package Jifty::Plugin::RecordHistory;
use strict;
use warnings;
use base qw/Jifty::Plugin/;

our $VERSION = '0.08';

sub init {
    Jifty->web->add_css('record-history.css');
}

1;

__END__

=head1 NAME

Jifty::Plugin::RecordHistory - track all changes made to a record class

=head1 SYNOPSIS

Add the following to your config:

    framework:
        Plugins:
            - RecordHistory: {}

Add the following to one or more record classes:

    use Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory;

=head1 DESCRIPTION

When you use L<Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory> in a
record class, we add a C<changes> method which returns an
L<Jifty::Plugin::RecordHistory::Model::ChangeCollection>. These changes describe
the updates made to the record, including its creation. Some changes also have
C<change_fields> which describe updates to the individual fields of the record.

You do not need to do anything beyond adding C<RecordHistory> to your plugins
and using the mixin to your record class(es) to enjoy transaction history. The
mixin even hooks into Jifty itself to observe record creation, updates, and
deletions.

=head2 Configuration

When you're importing the mixin you have several options to control the behavior
of history. Here are the defaults:

    use Jifty::Plugin::RecordHistory::Mixin::Model::RecordHistory (
        cascaded_delete => 1,
        delete_change   => 0,
    );

If C<cascaded_delete> is true, then
L<Jifty::Plugin::RecordHistory::Model::Change> and
L<Jifty::Plugin::RecordHistory::Model::ChangeField> records are deleted at the
same time the original record they refer to is deleted. If C<cascaded_delete>
is false, then the Change and ChangeField records persist even if the original
record is deleted.

If C<delete_change> is true, then when your record is deleted we create a
L<Jifty::Plugin::RecordHistory::Model::Change> record whose type is C<delete>.
If C<delete_change> is false, then we do not record the deletion. If
both C<cascaded_delete> I<and> C<delete_change> are true, then you will end up
with only one change after the record is deleted -- the C<delete>.

=head2 Grouping

By default, the only mechanism that groups together change_fields onto a single
change object is L<Jifty::Action::Record::Update> (and its subclasses that do
not override C<take_action>). But if you want to make a number of field updates
that need to be grouped into a single logical change, you can call
C<start_change> and C<end_change> yourself on the record object.

=head2 Views

If you want to display changes for a record class, mount the following into
your view tree to expose a default view at C</foo/history?id=42> (or you can of
course set C<id> via dispatcher rule).

    use Jifty::Plugin::RecordHistory::View;
    alias Jifty::Plugin::RecordHistory::View under '/foo/history', {
        object_type => 'Foo',
    };

Alternatively, if you want to extend the default templates, you can subclass
L<Jifty::Plugin::RecordHistory::View> in the same way as
L<Jifty::View::Declare::CRUD>.

=head2 Access control

When we read a Change record, we simply ask if the current user can read the
corresponding record.

Otherwise, when we create (or update or delete) Change records, we demand that
the current user is a superuser. In our C<after_set> and C<before_delete>
hooks, we perform these operations as superuser.

We require superuser so that ordinary users cannot use
L<Jifty::Plugin::REST> or similar to inject forged Change entries.

Also, when we create a Change record, we do it as the superuser because if by
updating a record the ordinary user loses access to update the record, then
they will get a permission error when we go to create the corresponding Change.
So not only does that change never end up in the record's history, but also
Jifty complains permission denied to the user directly.

=head1 SEE ALSO

L<Jifty::Plugin::ActorMetadata>

=head1 AUTHOR

Shawn M Moore C<< <sartak@bestpractical.com> >>

=head1 LICENSE

Jifty::Plugin::RecordHistory is Copyright 2011 Best Practical Solutions, LLC.
Jifty::Plugin::RecordHistory is distributed under the same terms as Perl itself.

=cut

