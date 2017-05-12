package Git::Release::Branch;
use 5.12.0;
use Moose;
use File::Spec;
use File::Path qw(mkpath);
use Git;

has name => ( is => 'rw' , isa => 'Str' );


# ref:  remotes/origin/branch_name (remote)
# ref:  branch_name (local)

has ref => ( is => 'rw' );

has tracking_ref => ( is => 'rw', isa => 'Str' );

has manager => ( is => 'rw' );

has remote => ( is => 'rw' );

has is_deleted => ( is => 'rw' );

sub BUILD {
    my ($self,$args) = @_;
    unless( $args->{ref} ) {
        $args->{ref} = $args->{name} if $args->{name};
    } else {
        $args->{ref} =~ s{^refs/}{}; # always strip refs prefix
    }

    $args->{tracking_ref} =~ s{^refs/}{} if $args->{tracking_ref};

    unless( $args->{remote} ) {
        my $remote_name = $self->parse_remote_name($args->{ref});
        $self->remote($remote_name);
    }
    unless( $args->{name} ) {
        my $name = $self->strip_remote_prefix( $args->{ref} );
        $args->{name} = $name;
        $self->name($name);
    }
    $self->load_tracking_ref;
    return $args;
}

sub load_tracking_ref {
    my ($self) = @_;
    # remote tracking ref
    unless ( $self->tracking_ref ) {
        # try to get tracking ref
        my %tracking = $self->manager->tracking_list;
        my $ref = $tracking{ $self->name } 
            if $self->name && defined $tracking{ $self->name };
        $ref =~ s{^refs/}{} if $ref;
        $self->tracking_ref( $ref ) if $ref;
    } 
}


=head2 parse_remote_name

Parse remote name from ref, like:

    remotes/origin/branch_name

=cut

sub parse_remote_name {
    my ($self,$ref) = @_;
    return unless $ref;
    my $new = $ref;
    chomp $new;
    my ($remote) = ($new =~ m{^remotes/([^/]+?)\/});
    return $remote;
}

=head2 strip_remote_prefix

Strip remotes prefix from branch ref string

    remotes/origin/branch_name

To

    origin/branch_name

=cut

sub strip_remote_prefix {
    my ($self,$ref) = @_;
    my $new = $ref;
    $new =~ s{^remotes\/([^/]+?)\/}{};
    return $new;
}




=head2 prefix

Get branch prefix name, for remote branch, return remotes/{prefix}

For local branch, return {prefix}

=cut

sub prefix { 
    my $self = shift;
    my ($prefix) = ($self->name =~ m{^([^/]*)/}i);
    return $prefix;
}

sub is_feature { 
    my $self = shift;
    return $self->prefix eq 'feature';
}

sub is_ready { 
    my $self = shift;
    return $self->prefix eq 'ready';
}

sub is_local { return ! $_[0]->is_remote; }

sub is_remote { return $_[0]->ref =~ m{^remotes/}; }

sub remote_name {  
    my $self = shift;
    return if $self->remote;
    if($self->is_remote) {
        return $self->parse_remote_name( $self->ref );
    } elsif( $self->tracking_ref ) {
        return $self->parse_remote_name( $self->tracking_ref );
    }
}


# return remote object
sub get_remote { 
    my $self = shift;
    return $self->manager->remote->get( $self->remote_name );
}

sub remote_tracking_branch {
    my $self = shift;
    return $self->manager->branch->new_branch(ref => $self->tracking_ref);
}

sub has_tracking_ref {
    return $_[0]->tracking_ref ? 1 : 0;
}


=head2 create

create branch

=cut

sub create {
    my ($self,%args) = @_;
    my @args = qw(branch);

    # git branch --set-upstream develop origin/develop
    CORE::push @args, '--set-upstream' if $args{upstream};
    CORE::push @args, $self->name;
    CORE::push @args, $args{from} || 'master';

    $self->manager->repo->command(@args);
    return $self;
}

# options:
#
#    ->delete( force => 1 , remote => 1 );
#    ->delete( force => 1 , remote => ['origin','github'] );
#    ->delete( force => 1 , remote => 'github' );

sub delete {
    my ($self,%args) = @_;
    if( $args{remote} ) {
        if( ref($args{remote}) eq 'ARRAY' ) {
            $self->manager->repo->command( 'push' , $_ , ':' . $self->name ) 
                    for @{ $args{remote} };
        } 
        elsif( $args{remote} == 1 && $self->remote_name ) {
            $self->manager->repo->command( 'push' , $self->remote_name , ':' . $self->name );
        }
        else {
            $self->manager->repo->command( 'push' , ($args{remote}) , ':' . $self->name );
        }
    }
    elsif( $args{local} || $self->is_local ) {
        $self->manager->repo->command( 'branch' , $args{force} ? '-D' : '-d' , $self->ref );
    }
    elsif( $self->is_remote ) {
        $self->manager->repo->command( 'push', $self->remote, ':' . $self->name );
    }
    $self->is_deleted(1);
    return $self;
}


=head2 local_rename

Rename branch locally.

=cut

sub local_rename {
    my ($self,$new_name,%args) = @_;
    if( $self->is_local ) {
        if( $args{force} ) {
            $self->manager->repo->command( 'branch','-m',$self->name,$new_name);
        } else {
            $self->manager->repo->command( 'branch','-M',$self->name,$new_name);
        }
        $self->name($new_name);
        $self->update_ref($new_name);
    }
}


=head2 update_ref

update_ref by branch name

=cut

sub update_ref {
    my ($self,$name) = @_;
    if( $self->is_remote ) {
        $self->ref( join '/','remotes',$self->remote,$name );
    } elsif( $self->is_local ) {
        $self->ref( $name );
    }
}

sub rename {
    my ($self,$new_name,%args) = @_;
    if( $self->is_remote ) {
        # if local branch is found, then checkout it 
        # if not found, then checkout remote tracking branch
        my $local = $self->manager->branch->find_local_branches($self->name);
        $local = $self->checkout unless $local;
        $local->pull( 
            remote => $self->remote, 
            no_edit => 1, 
            fast_forward => 1 
        );
        $local->delete( remote => 1 );

        $local->local_rename( $new_name , %args );

        $local->push( $self->remote );
        $self->name($new_name);
        $self->update_ref($new_name);
    }
    elsif( $self->is_local && $self->tracking_ref ) {
        $self->delete( remote => 1 );
        $self->local_rename( $new_name , %args );
        $self->push( $self->remote_name );  # push to tracking remote
    }
    elsif( $self->is_local ) {
        $self->local_rename($new_name,%args);
    }
}

sub checkout {
    my $self = shift;
    if( $self->is_remote ) {
        # find local branch to checkout if the branch exists
        my $local = $self->manager->branch->find_local_branches($self->name);
        if( $local ) {
            $self->manager->repo->command( 'checkout' , $local->name );
            return $local;
        } else {
            $self->manager->repo->command( 'checkout' , '-t' , $self->ref , '-b' , $self->name );
            return $self->manager->branch->new_branch( ref => $self->name );  # local branch instance
        }
    }
    elsif( $self->is_local && $self->tracking_ref ) {
        my $local = $self->manager->branch->find_local_branches($self->name);
        if( $local ) {
            $self->manager->repo->command( 'checkout' , $local->name );
        } else {
            $self->manager->repo->command( 'checkout' , '-t' , $self->tracking_ref , '-b' , $self->name );
        }
        return $self;
    }
    elsif( $self->is_local ) {
        $self->manager->repo->command( 'checkout' , $self->name );
    } 
}

sub merge {
    my ($self,$b, %args) = @_;
    my @args = ( 'merge' );
    CORE::push @args, '--ff' if $args{fast_forward};
    CORE::push @args, '--edit' if $args{edit};
    CORE::push @args, '--no-edit' if $args{no_edit};
    CORE::push @args, '--squash' if $args{squash};
    CORE::push @args, '--quiet' if $args{quiet};
    CORE::push @args, ref($b) eq 'Git::Release::Branch' ? $b->ref : $b;
    return $self->manager->repo->command( @args );
}

sub rebase_from {
    my ($self,$from) = @_;
    if( ! ref($from) ) {
        $from = $self->manager->_new_branch( ref => $from );
    }
    my @ret = $self->manager->repo->command( 'rebase' , $from->name , $self->name );
    return @ret;
}

sub push {
    my ($self,$remote,%args) = @_;
    $remote ||= $self->remote;
    die "remote name is requried." unless $remote;
    my @args = ('push');

    # git push --set-upstream origin develop
    CORE::push @args, '--set-upstream' if $args{upstream};
    CORE::push @args, '--tags' if $args{tags};
    CORE::push @args, '--all' if $args{all};
    CORE::push @args, $remote;
    CORE::push @args, $self->name;
    $self->manager->repo->command(@args);

    if( $args{upstream} ) {
        # update tracking_ref
        # eg:  refs/remotes/origin/branch
        $self->tracking_ref(join '/','refs','remotes',$remote,$self->name);
    }

}

sub push_to_remotes {
    my $self = shift;
    $self->push($_)
        for $self->manager->remote->list;
}



# Remove remote tracking branches
# if self is a local branch, we can check if it has a remote branch
sub delete_remote_branches {
    my $self = shift;
    my $name = $self->name;
    my @remotes = $self->manager->repo->command( 'remote' );
    my @rbs = $self->manager->list_remote_branches;

    for my $remote ( @remotes ) {
        # has tracking branch at remote ?
        if( grep m{$remote/$name},@rbs ) {
            $self->manager->repo->command( 'push' , $remote , '--delete' , $self->name );
        }
    }
}

sub replace_prefix {
    my ($self,$new_prefix,%args) = @_;
    if ($self->prefix) {
        my $new_name = $self->name;
        $new_name =~ s{^([^/]*)/}{$new_prefix/};
        $self->rename( $new_name, %args );
    }
}

sub remove_prefix {
    my ($self,%args) = @_;
    if ($self->prefix) {
        my $new_name = $self->name;
        $new_name =~ s{^([^/]*)/}{};
        $self->rename( $new_name, %args );
    }
}

sub prepend_prefix {
    my ($self,$prefix,%args) = @_;
    return if $self->prefix && $self->prefix eq $prefix;
    my $new_name = join '/',$prefix,$self->name;
    $self->rename($new_name,%args);
}

sub pull { 
    my ($self,%args) = @_;
    my @a = ('pull');
    CORE::push @a, '--rebase' if $args{rebase};
    CORE::push @a, '--quiet'  if $args{quiet};
    CORE::push @a, '--no-commit'  if $args{no_commit};
    CORE::push @a, '--commit'  if $args{commit};
    CORE::push @a, '--ff'  if $args{fast_forward};
    CORE::push @a, '--edit'  if $args{edit};
    CORE::push @a, '--no-edit'  if $args{no_edit};
    CORE::push @a, '--squash'  if $args{squash};
    CORE::push @a, ($args{remote} || $self->remote_name || 'origin');
    CORE::push @a, ($args{name} || $self->name);
    return $self->manager->repo->command(@a);
}

sub move_to_ready {
    my $self = shift;
    my $name = $self->name;
    my $prefix = $self->manager->config->ready_prefix;
    return if $self->prefix && $self->prefix eq $prefix;

    my $new_name = $prefix . '/' . $name;
    say "Moving branch @{[ $self->name ]} to " , $new_name;
    $self->prepend_prefix( $prefix );
    return $self;
}

sub move_to_released {
    my $self = shift;
    my $name = $self->name;
    my $prefix = $self->manager->config->released_prefix;
    return if $self->prefix && $self->prefix eq $prefix;
    return if $self->prefix ne 'ready';  # if it's not with ready prefix, do not move to released/

    say "Moving branch @{[ $self->name ]} to released state.";
    $self->replace_prefix( $prefix );
    return $self;
}

sub get_doc_path {
    my $self = shift;
    my $docname = $self->name;
    return if $self->name eq 'HEAD';

    $docname =~ s/^@{[ $self->manager->config->released_prefix ]}//;
    $docname =~ s/^@{[ $self->manager->config->ready_prefix ]}//;

    my $ext = $self->manager->config->branch_doc_ext;

    my $dir = File::Spec->join( $self->manager->repo->wc_path , $self->manager->config->branch_doc_path );
    mkpath [ $dir ] if ! -e $dir ;
    return File::Spec->join( $dir , "$docname.$ext" );
}

sub default_doc_template {
    my $self = shift;
    return <<"END";
@{[ $self->name ]}
======

REQUIREMENT
------------

SYNOPSIS
------------

PLAN
------------

KNOWN ISSUES
------------

END
}

sub init_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;


    print "Initializing branch documentation.\n";
    open my $fh , ">" , $doc_path;
    print $fh $self->default_doc_template;
    close $fh;

    $self->edit_doc;
    print "Done.\n";
}

sub edit_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;

    # XXX:
    # launch editor to edit doc
#     my $bin = $ENV{EDITOR} || 'vim';
#     system(qq{$bin $doc_path}) == 0
#         or die "System failed: $?";

}

sub print_doc {
    my $self = shift;
    my $doc_path = $self->get_doc_path;
    return unless $doc_path;

    print "Branch doc path: $doc_path\n";

    # doc doesn't exists
    unless(-e $doc_path ){
        print "Branch doc $doc_path not found.\n";
        $self->init_doc;
        return;
    }

    if($doc_path =~ /\.pod$/) {
        system("pod2text $doc_path");
    }
    else {
        open my $fh , "<" , $doc_path;
        local $/;
        my $content = <$fh>;
        close $fh;
        print "===================\n";
        print $content , "\n";
        print "===================\n";
    }
}



1;
__END__
=head1

=head2 SYNOPSIS

    my $branch = $manager->branch->current;
    my $develop = $manager->branch->new_branch( 'develop' )->create( from => 'master' );

    $develop->delete;
    $develop->push;
    $develop->push('origin');
    $develop->push('github');
    $develop->push_to_remotes;

=head3 delete_remote_branches

=head3 move_to_ready 

=head3 move_to_released

=cut
