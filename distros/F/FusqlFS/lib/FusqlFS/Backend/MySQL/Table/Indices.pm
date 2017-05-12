use strict;
use 5.010;

package FusqlFS::Backend::MySQL::Table::Indices;
use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;
use parent 'FusqlFS::Artifact::Table::Lazy';

=head1 NAME

FusqlFS::Backend::MySQL::Table::Indices - 

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 EXPOSED STRUCTURE

=cut

sub init
{
    my $self = shift;
    $self->{template} = { '.order' => [] };
}

sub list
{
    my $self = shift;
    my ($table) = @_;
    my $data = $self->all_row('SHOW INDEX FROM `%s`', [$table]);
    return unless $data;

    my %keys = map { $_->{Key_name} => 1 } @$data;
    return [ keys %keys, @{$self->SUPER::list($table)} ];
}

sub get
{
    my $self = shift;
    my ($table, $name) = @_;
    unless ($self->SUPER::get($table, $name))
    {
        my $data = $self->all_row('SHOW INDEX FROM `%s` WHERE `Key_name` = ?', [$table], $name);
        return unless $data && @$data;

        my $result = { '.order' => [] };
        foreach my $item (@$data)
        {
            my $colname = $item->{Sub_part}? $self->ajoin($item->{Column_name}, $item->{Sub_part}): $item->{Column_name};
            push @{$result->{'.order'}}, $item->{Column_name};

            $result->{$colname}   = \"tables/$table/struct/$item->{Column_name}";
            $result->{'.unique'}  = 1 unless $item->{Non_unique};
            $result->{'.type'}    = $item->{Index_type};
            $result->{'.primary'} = 1 if $item->{Key_name} =~ /^PRI/;
        }

        return $result;
    }
}

sub rename
{
    my $self = shift;
    my ($table, $name, $newname) = @_;
    my $data = $self->get($table, $name) or return;
    $self->SUPER::rename($table, $name, $newname) or
        $self->drop($table, $name) and $self->store($table, $newname, $data);
}

sub drop
{
    my $self = shift;
    my ($table, $name) = @_;
    $self->SUPER::drop($table, $name) or $self->do('ALTER TABLE `%s` DROP INDEX `%s`', [$table, $name]);
}

sub store
{
    my $self = shift;
    my ($table, $name, $data) = @_;
    my $struct = $self->validate($data, {
        '-.primary' => '',
        '-.unique'  => '',
        '-.type'    => '',
        '.order'    => 'ARRAY',
    }, sub{
        my %columns = map { $self->asplit($_, 2) } grep !/^[.]/, keys %{$_[0]};
        my @order   = grep { exists $columns{$_} } @{$_->{'.order'}};

        my %order = map { $_ => 1 } @order;
        foreach (keys %columns)
        {
            push @order, $_ unless exists $order{$_};
        }
        my $columns = join(',', map {
            my $colname = "`$_`";
            $colname .= "($columns{$_})" if $columns{$_};
            $colname;
        } @order);
        $_->{'columns'} = $columns;
    }) or return;

    $self->drop($table, $name) and $self->do('ALTER TABLE `%s` ADD %s KEY %s %s (%s)',
    [
        $table,
        $struct->{'.primary'}? 'PRIMARY': ($struct->{'.unique'}? 'UNIQUE': ''),
        $struct->{'.primary'}? '': "`$name`",
        $struct->{'.type'}? 'USING '.$struct->{'.type'}: '',
        $struct->{'columns'},
    ]);
}

1;

