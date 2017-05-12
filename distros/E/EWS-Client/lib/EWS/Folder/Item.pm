package EWS::Folder::Item;
BEGIN {
  $EWS::Folder::Item::VERSION = '1.143070';
}

use Moose;
use Moose::Util::TypeConstraints;
use DateTime::Format::ISO8601;
use DateTime;
use HTML::Strip;
use Encode;

has ChildFolderCount => (
    is => 'ro',
    isa => 'Int',
);

has DisplayName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has ExtendedProperty => (
    is => 'ro',
    isa => 'ArrayRef',
);

has FolderClass => (
    is => 'ro',
    isa => 'Str',
    required => 0,
);

has FolderId => (
    is => 'ro',
    isa => 'Any',
    lazy_build => 1,
);

sub _build_FolderId {
    my $self = shift;
    return $self->{Id};
}

has FudgeSize => (
    is => 'ro',
    isa => 'Int',
    lazy_build => 1,
);

sub _build_FudgeSize {
    my $self = shift;
    # This appears to be the difference between the sizes returned from Exchange
    # and those in Outlook
    my $size = $self->MessageSize;
    if ( defined( $self->TotalCount ) ) {
        $size += $self->TotalCount * 8000;
    }
    return $size;
}

has MessageSize => (
    is => 'ro',
    isa => 'Int',
    lazy_build => 1,
);

sub _build_MessageSize {
    my $self = shift;
    my $size = 0;
    foreach my $prop (@{$self->{ExtendedProperty}}) {
        if ($prop->{ExtendedFieldURI}->{PropertyTag} eq '0xe08') {
            $size = $prop->{Value};
        }
    } 
    return $size;
}

has ParentFolderId => (
    is => 'ro',
    isa => 'Any',
    lazy_build => 1,
);

sub _build_ParentFolderId {
    my $self = shift;
    return $self->{Id};
}

has TotalCount => (
    is => 'ro',
    isa => 'Int',
);

has SubFolders => (
    is => 'ro',
    isa => 'ArrayRef[EWS::Folder::Item]',
    lazy_build => 1,
);

sub _build_SubFolders {
    my $self = shift;
    return exists $self->{items} ? $self->{items} : [];
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    return $params;
}

sub SubFolder_count {
    my $self = shift;
    return scalar @{$self->SubFolders};
}

has iterator => (
    is => 'ro',
    isa => 'MooseX::Iterator::Array',
    handles => [qw/
        next
        has_next
        peek
        reset
    /],
    lazy_build => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub _build_iterator {
    my $self = shift;
    return MooseX::Iterator::Array->new( collection => $self->SubFolders );
}

sub printAndSumSizes {
    my ($self, $pad) = @_;
#    my $size = $self->MessageSize;
    my $size = $self->FudgeSize;
    my $dispSize = $size;

    if ( $dispSize > 1024 ) {
        $dispSize = commify($dispSize / 1024). " KB";
    }
    if ( $self->ChildFolderCount > 0 ) {
        print $pad. $self->DisplayName. ":\n";
        foreach my $item (@{$self->SubFolders}) {
            $size += $item->printAndSumSizes($pad." ");
        }
        print $pad. $self->DisplayName. " Size=". $dispSize. " Total=$size\n";
    }
    else {
        print $pad. $self->DisplayName. " Size=". $dispSize. "\n";
    }
    return $size;
}

sub commify {
        my $text = reverse sprintf "%.0f", $_[0];
        $text =~ s/(\d\d\d)(?=\d)(?!d*\.)/$1,/g;
        return scalar reverse $text;
}

sub toString {
    my ($self, $pad) = @_;

    print $pad. $self->DisplayName. ": Size=". $self->MessageSize. "\n";
    if ( $self->ChildFolderCount > 0 ) {
        foreach my $item (@{$self->SubFolders}) {
            $item->toString($pad." ");
        }
    }
}

1;
