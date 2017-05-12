package EPUB::Parser::Util::Archive;
use strict;
use warnings;
use Carp;
use Smart::Args;
use Archive::Zip qw( AZ_OK );

sub new {
    args(
        my $class => 'ClassName',
        my $data => { isa => 'Archive::Zip' },
    );

    bless { data => $data } => $class;
}

sub get_member_data {
    args(
        my $self      => 'Object',
        my $file_path => 'Str',
    );

    my $member = $self->{data}->memberNamed($file_path);
    croak "$file_path not found" unless ($member);

    my ( $member_data, $AZ_status ) = $member->contents();
    croak "$file_path: error Archive::Zip status = $AZ_status" if ($AZ_status != AZ_OK);

    return $member_data;

}

sub get_members {
    my $self = shift;
    my $args = shift || {};
    $args->{zip} = $self;

    EPUB::Parser::Util::Archive::Iterator->new($args);
}


package EPUB::Parser::Util::Archive::Iterator;
use strict;
use warnings;
use Carp;
use Smart::Args;
use Archive::Zip qw( AZ_OK );

sub new {
    args(
        my $class => 'ClassName',
        my $zip   => { isa => 'EPUB::Parser::Util::Archive'},
        my $files_path => 'ArrayRef[Str]',
    );

    bless {
        zip            => $zip,
        files_path     => $files_path,
        current_index  => -1,
        current_member => undef,
    } => $class;
    
}

sub size {
    my $self = shift;
    scalar @{$self->{files_path}};
}

sub current_file_path {
    my $self = shift;
    $self->{files_path}->[$self->{current_index}];
}

sub is_last {
    my $self = shift;
    $self->{current_index} == ( $self->size - 1 );
}

sub reset {
    my $self = shift;
    $self->{current_index} = -1;
    $self->data(undef);
}

sub first {
    my $self = shift;
    $self->reset;
    $self->next;
}

sub all {
    my $self = shift;
    $self->reset;
    my @data;
    while( my $member = $self->next ) {
        push @data, $member->data;
    };

    return @data;
}

sub next {
    my $self = shift;
    return if $self->is_last;

    $self->_next_member;

    return $self;
}

sub _next_member {
    my $self = shift;

    $self->{current_index}++;
    my $member = $self->{zip}->{data}->memberNamed($self->current_file_path);
    croak $self->current_file_path . ' not found' unless $member;

    my ( $member_data, $AZ_status ) = $member->contents();
    croak $self->current_file_path . ": error Archive::Zip status = $AZ_status" if ($AZ_status != AZ_OK);

    $self->data($member_data);

}

sub data {
    my $self = shift;
    if (@_) {
        $self->{data} = shift;
    }
    $self->{data};
}

{ no warnings; *path = \&current_file_path; }

1;
