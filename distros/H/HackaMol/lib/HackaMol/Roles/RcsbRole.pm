package HackaMol::Roles::RcsbRole;
$HackaMol::Roles::RcsbRole::VERSION = '0.053';
# ABSTRACT: Read files with molecular information
use Moose::Role;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsPaths/;

has 'sync_overwrite' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    lazy => 1,
);

has 'local_pdb_path' => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    default => '~/myPDB/pdb',
    lazy => 1,
);

has 'local_cif_path' => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    default => '~/myPDB/cif',
    lazy => 1,
);

has 'rcsb_rest_addr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'http://www.rcsb.org/pdb/rest/',
    lazy => 1,
);

has 'rcsb_ftp_addr' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'ftp.rcsb.org',
    lazy => 1,
);

has 'ftp_user' => (
    is  => 'ro',
    isa => 'Str',
    default => 'anonymous',
    lazy => 1,
);

has 'ftp_password' => (
    is  => 'ro',
    isa => 'Str',
    default => 'anonymous',
    lazy => 1,
);

sub pdbid_local_path {
    my $self  = shift;
    my $pdbid = lc( shift );

    die "Invocation: ->pdb_id_local_path(pdbid,[cif|pdb]?)" 
        unless length($pdbid) == 4;
    
    my $type = shift || 'cif';

    my $path_method = "local_${type}_path";

    # may or may not exist
    my $path = $self->$path_method->child(
                                substr( $pdbid, 1, 2 ) . "/$pdbid.$type" );

    return $path;    

}


sub local_pdbs { shift->_local_cifs_pdbs('pdb') }
sub local_cifs { shift->_local_cifs_pdbs('cif') }

sub _local_cifs_pdbs {
    my $self = shift;
    my $type = shift;
    my $path_method = "local_${type}_path";
    my @files =  map  { $_->children(qr/\.$type$/) }
                 grep { $_->is_dir } $self->$path_method->children; 
    return @files;
}


sub rcsb_sync_local {
    my $self = shift;
    my $type = shift;
    die "Invocation-> rcsb_sync_local('cif|pdb')" unless $type =~ /(?:cif|pdb)/;
    my @pdbids = map{ lc($_) } @_;

    my $local_types = "local_${type}s";
    my @local_pdbids = map{ $_->basename(qr/\.$type$/)} $self->$local_types;
    my %seen = map {$_ => 1} @local_pdbids;

    unless ($self->sync_overwrite){
        my $count = @pdbids;
        @pdbids =  grep {! exists($seen{$_})} @pdbids;
        if ($count != @pdbids){
          my $local_path = "local_${type}_path";
          warn "ignoring @{[$count - @pdbids]} files contained in @{[$self->$local_path]}\n";
        }
    }  

    return ([],[]) unless @pdbids;
    print "syncing @{[scalar @pdbids]} $type files\n";
    my ($synced_pdbids,$missed_pdbids) = $self->rcsb_ftp_fetch($type, \@pdbids );
    return ($synced_pdbids,$missed_pdbids);
}

sub rcsb_ftp_fetch {

    require IO::Uncompress::Gunzip;
    my $self        = shift;
    my $type = shift;
    die "Invocation-> rcsb_sync_local('cif|pdb')" unless $type =~ /(?:cif|pdb)/;
    my $pdbids      = shift;
    my $parent_path = shift;
    my $local_path = "local_${type}_path";
    $parent_path =  $self->$local_path unless $parent_path;

    my $cwd_base = $type eq 'cif' ? 'mmCIF' : 'pdb';
    my $ftp = $self->ftp_connect("/pub/pdb/data/structures/divided/$cwd_base");

    my @pdbids = map { lc($_) } @$pdbids;
    my @fetched;

    my @missed;
    foreach my $pdbid (@pdbids) {
        print "fetching $pdbid\n";
        my $gz = "$pdbid.cif.gz";
        my $subdir = substr( $pdbid, 1, 2 );

        $ftp->get("$subdir/$gz")
            or do {
            print "unable to fetch $pdbid\n";
            print $ftp->message;
            die "ftp download problems" if ($ftp->message =~ /load was .+ when you connected/);
            push @missed,$pdbid;
            next
        };

        my $dest_par = $parent_path->child("$subdir");
        $dest_par->mkpath unless $dest_par->exists;
        my $dest = $dest_par->child("$pdbid.$type");
        IO::Uncompress::Gunzip::gunzip( $gz => $dest->stringify )
            or die "unable to gunzip $gz";
        unlink $gz;
        push @fetched, $pdbid;
    }

    $ftp->quit;
    return (\@fetched,\@missed);
}


sub ftp_connect {
    # connects to FTP via rcsb_ftp_addr and sets working directory to path if passed
    require Net::FTP;
    
    my $self = shift;
    my $path = shift;
    my $host = $self->rcsb_ftp_addr;
    my $user = $self->ftp_user;
    my $pass = $self->ftp_password;
    
    my $ftp  = Net::FTP->new($host);
    $ftp->login( $user, $pass ) or die "cannot login to rcsb ftp addr";
    if($path){
        $ftp->cwd($path) or die "cannont cwd to $path";
    }
    $ftp->binary();
    return $ftp;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

HackaMol::Roles::RcsbRole - Read files with molecular information

=head1 VERSION

version 0.053

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
