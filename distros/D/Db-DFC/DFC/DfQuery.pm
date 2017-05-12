# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
#
# DfQuery (com.documentum.fc.client.DfQuery)
# ------------------------------------------------------------------ #

package DfQuery;
@ISA = (IDfQuery);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::DfQuery';
use JPL::Class 'com.documentum.fc.client.IDfCollection';



sub new {
    my $new = JPL::AutoLoader::getmeth('new',[],[]);
    my $rv;

    ## CONSTRUCTOR: com.documentum.fc.client.DfQuery()

    eval { $rv = com::documentum::fc::client::DfQuery->$new(); };

    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless(\$rv,IDfQuery);
        return \$rv;
    }
}

sub execute {
	## METHOD: com.documentum.fc.client.IDfCollection execute(com.documentum.fc.client.IDfSession,int)
    my ($self,$p0,$p1) = @_;
    my $execute = JPL::AutoLoader::getmeth('execute',['com.documentum.fc.client.IDfSession','int'],['com.documentum.fc.client.IDfCollection']);
    my $rv = "";
    eval { $rv = $$self->$execute($$p0,$p1); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfCollection);
        return \$rv;
    }
}

sub getDQL {
	## METHOD: java.lang.String getDQL()
    my $self = shift;
    my $getDQL = JPL::AutoLoader::getmeth('getDQL',[],['java.lang.String']);
    my $rv = "";
    eval { $rv = $$self->$getDQL(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setBatchSize {
	## METHOD: void setBatchSize(int)
    my ($self,$p0) = @_;
    my $setBatchSize = JPL::AutoLoader::getmeth('setBatchSize',['int'],[]);
    my $rv = "";
    eval { $rv = $$self->$setBatchSize($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub getBatchSize {
	## METHOD: int getBatchSize()
    my $self = shift;
    my $getBatchSize = JPL::AutoLoader::getmeth('getBatchSize',[],['int']);
    my $rv = "";
    eval { $rv = $$self->$getBatchSize(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}

sub setDQL {
	## METHOD: void setDQL(java.lang.String)
    my ($self,$p0) = @_;
    my $setDQL = JPL::AutoLoader::getmeth('setDQL',['java.lang.String'],[]);
    my $rv = "";
    eval { $rv = $$self->$setDQL($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        return $rv;
    }
}


1;

# ------------------------------------------------------------------ #
#                                <SDG><
# ------------------------------------------------------------------ #
