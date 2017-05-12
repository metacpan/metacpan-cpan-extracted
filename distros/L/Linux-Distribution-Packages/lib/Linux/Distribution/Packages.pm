package Linux::Distribution::Packages;

use 5.006000;
use strict;
use warnings;

use base qw(Linux::Distribution);

our $VERSION = '0.05';

my %commands = (
    'debian'                => 'dpkg',
    'gentoo'                => 'equery',
    'fedora'                => 'rpm',
    'redflag'               => 'rpm',
    'redhat'                => 'rpm',
    'slackware'             => 'pkgtool',
    'suse'                  => 'rpm',
    'ubuntu'                => 'dpkg',
);

our @EXPORT_OK = qw(distribution_packages distribution_write format);

sub new {
    my $package = shift;
    my $options = shift;
   
    my $self = {
        'command'           => '',
        'format'            => 'native',
        '_data'             => '',
        'output_file'       => ''
    };

    foreach my $option (keys %{$options}){
	$self->{$option} = $options->{$option};
    }

    bless $self, $package;
    $self->SUPER::new();
    $self->distribution_name();
    $self->distribution_packages();
    return $self;
}

sub distribution_packages {
    my $self = shift || new();
    if ($commands{$self->{'DISTRIB_ID'}}){
        bless $self, 'Linux::Distribution::Packages::' . $commands{$self->{'DISTRIB_ID'}};
    } else {
        print "Distribution [ $self->{'DISTRIB_ID'} ] not supported\n";
        exit;
    }
    $self->_retrieve_all();
}

sub distribution_write {
    my $self = shift;
    my $options = shift;
    foreach my $option (keys %{$options}){
        $self->{$option} = $options->{$option};
    }
    my $print_function = '_list_' . $self->{'format'};
    if ( $self->{'format'} ne 'xml'){
        $self->_open_output_fh();
    }
    $self->$print_function();
    if ( $self->{'format'} ne 'xml'){
        $self->_close_output_fh();
    }
    return 1;
}

sub format {
    my $self = shift;
    $self->{'format'} = shift || 'native';
}

sub _retrieve_all {
    my $self = shift;
    $self->_command();
    $self->{'_data'} = ` $self->{'command'} `;
    die "Error $? running \'$self->{'command'}\'\n" if $?;
}

sub _list_native {
    my $self = shift;
    my $output = $self->{'output_file_handle'};
    print { $output || *STDOUT } $self->{_data};
}

sub _list_xml {
    require XML::Writer;
    my $self = shift;
    my $writer;

    my $writer_options = {DATA_MODE => 1, DATA_INDENT => 2};
    my $output;
    if (defined $self->{'output_file'}){
        require IO::File;
        $output = new IO::File(">$self->{'output_file'}");
	$writer_options->{'OUTPUT'} = $output;
    }
    if ($self->{'format'} =~ m/xml/i){
        $writer = new XML::Writer(%{$writer_options});
        $writer->startTag('distribution', "name" => $self->{'DISTRIB_ID'}, "release" => $self->distribution_version());
    }
    my $hash = $self->_parse($writer);
    $writer->endTag('distribution');
}

sub _list_csv {
    my $self = shift;
    $self->_parse();
}

sub _row_csv {
    my $self = shift;
    my $output = $self->{'output_file_handle'};
    print { $output || *STDOUT } "\'" . join("\',\'", @_) . "\'\n";
}

sub _parse {
    my $self = shift;
    my $row_func='_row_' . $self->{'format'};
    my @data = split '\n', $self->{'_data'};
    foreach my $row (@data){
        $self->$row_func($row);
    }
}

sub _open_output_fh {
    my $self = shift;
    if ($self->{'output_file'}){
        open FH, ">>$self->{'output_file'}";
        $self->{'output_file_handle'} = *FH;
    } else {
        delete $self->{'output_file_handle'};
        delete $self->{'output_file'};
    }
}

sub _close_output_fh {
    my $self = shift;
    if ($self->{'output_file'}){
        close $self->{'output_file_handle'};
        delete $self->{'output_file_handle'};
    }
}

sub _command {
    my ( $self, $command ) = @_;
    # Add options not really yet implemented
    if ($self->{'options'}){ $command .= ' ' . $self->{'options'}; }
    $self->{'command'} = $command;
}

return 1;

package Linux::Distribution::Packages::equery;
use base qw(Linux::Distribution::Packages);

sub _command {
    my $self = shift;
    $self->SUPER::_command('equery list');
}

sub _parse {
    my $self = shift;
    my @data = split '\n', $self->{_data};
    my $writer=shift;
    foreach my $row (@data){
        my ($dir, $pkg, $ver);
        next if $row =~ m/.*installed packages.*/;
        if ($row =~ m/\-(r\d+)$/){ 
            ($dir, $pkg, $ver) = $row =~ m/(.+)\/(.+)\-(.+(\-(r\d+)))$/;
        } else {
            ($dir, $pkg, $ver) = $row =~ m/(.+)\/(.+)\-(.+)/;
        }
        if ($self->{'format'} =~ m/xml/i){ $writer->emptyTag('package', 'name' => $pkg, 'version' => $ver , 'category' => $dir); next; }
        my $row_func='_row_' . $self->{'format'};
        $self->$row_func($dir, $pkg, $ver, '');
    }
}

return 1;

package Linux::Distribution::Packages::dpkg;
use base qw(Linux::Distribution::Packages);

sub _command {
    my $self = shift;
    $self->SUPER::_command('dpkg --list');
}

sub _parse {
    my $self = shift;
    my @data = split '\n', $self->{_data};
    my $writer=shift;
    foreach my $row (@data){
        my ($ii, $desc, $pkg, $ver);
        next if $row =~ m/^(Desired|\||\+).*/;
        ($ii, $pkg, $ver, $desc) = $row =~ m/^(.+?)\s+(.+?)\s+(.+?)\s+(.+)$/;
        if ($self->{'format'} =~ m/xml/i){ $writer->emptyTag('package', 'name' => $pkg, 'version' => $ver , 'description' => $desc); next; }
        my $row_func='_row_' . $self->{'format'};
        $self->$row_func('', $pkg, $ver, $desc);
    }
}

return 1;


package Linux::Distribution::Packages::rpm;
use base qw(Linux::Distribution::Packages);

sub _command {
    my $self = shift;
    $self->SUPER::_command('rpm -qa');
}

sub _parse {
    my $self = shift;
    my @data = split '\n', $self->{_data};
    my $writer=shift;
    foreach my $row (@data){
        my ($pkg, $ver);
        next if $row =~ m/^(Desired|\||\+).*/;
        ($pkg, $ver) = $row =~ m/^(.+)\-+(.+\-.+)$/;
        if ($self->{'format'} =~ m/xml/i){ $writer->emptyTag('package', 'name' => $pkg, 'version' => $ver ); next; }
        my $row_func='_row_' . $self->{'format'};
        $self->$row_func('', $pkg, $ver, '');
    }
}

package Linux::Distribution::Packages::pkgtool;
use base qw(Linux::Distribution::Packages);

sub _command {
    my $self = shift;
    $self->SUPER::_command('ls /var/log/packages');
}

sub _parse {
    my $self = shift;
    my @data = split '\n', $self->{_data};
    my $writer=shift;
    foreach my $row (@data){
        my ($pkg, $ver);
        ($pkg, $ver) = $row =~ m/^(.+)\-(.+)\-.+\-\d+$/;
        if ($self->{'format'} =~ m/xml/i){ $writer->emptyTag('package', 'name' => $pkg, 'version' => $ver ); next; }
        my $row_func='_row_' . $self->{'format'};
        $self->$row_func('', $pkg, $ver, '');
    }
}
return 1;

__END__


=head1 NAME

Linux::Distribution::Packages - list all packages on various Linux distributions 

=head1 SYNOPSIS

  use Linux::Distribution::Packages qw(distribution_packages distribution_write);

  $linux = new Linux::Distribution::Packages({'format' => 'csv', 'output_file' => 'packages.csv'});
  $linux->distribution_write();

  # Or you can (re)set the options when you write.
  $linux->distribution_write({'format' => 'xml', 'output_file' => 'packages.xml'});

  # If you want to reload the package data
  $linux->distribution_packages();

=head1 DESCRIPTION

This is a simple module that uses Linux::Distribution to guess the linux 
distribution and then uses the correct commands to list all the packages 
on the system and then output them in one of three formats:  native, csv, 
and xml.

Distributions currently working:  debian, ubuntu, fedora, redhat, suse, 
gentoo, slackware, redflag.

The module inherits from Linux::Distribution, so can also use its calls.

=head2 EXPORT

None by default.

=head1 TODO

* Add the capability to correctly get packages for all recognized distributions.
* Seperate out parsing from writing.  Parse data to hash and give access to hash. 
Then write the formatted data from the hash.

=head1 AUTHORS

Judith Lebzelter, E<lt>judith@osdl.orgE<gt>
Alberto Re, E<lt>alberto@accidia.netE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

