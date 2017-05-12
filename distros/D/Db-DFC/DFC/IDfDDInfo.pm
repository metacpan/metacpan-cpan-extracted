# ------------------------------------------------------------------ #
# Db::DFC Version 0.4 -- Thu Feb 22 22:04:43 2001
# (C) 2000-2001 M.S. Roth
# 
# IDfDDInfo (com.documentum.fc.client.IDfDDInfo)
# ------------------------------------------------------------------ #

package IDfDDInfo;
@ISA = (Serializable);

use JPL::AutoLoader;
use JPL::Class 'com::documentum::fc::client::IDfDDInfo';
use JPL::Class 'com.documentum.fc.common.IDfProperties';

use constant DDTypeName => "type_name";
use constant DDValConstraint => "val_constraint";
use constant DDValConstraintDep => "val_constraint_dep";
use constant DDValConstraintEnf => "val_constraint_enf";
use constant DDValConstraintMsg => "val_constraint_msg";
use constant DDIgnoreConstraints => "ignore_constraints";
use constant DDAttrName => "attr_name";
use constant DDIsHidden => "is_hidden";
use constant DDIsRequired => "is_required";
use constant DDReadOnly => "read_only";
use constant DDNotNull => "not_null";
use constant DDLabelText => "label_text";
use constant DDCommentText => "comment_text";
use constant DDHelpText => "help_text";
use constant DDFormatPattern => "format_pattern";
use constant DDMapDisplayString => "map_display_string";
use constant DDMapDataString => "map_data_string";
use constant DDMapDescription => "map_description";
use constant DDCondValueAssist => "cond_value_assist";
use constant DDValueAssistDep => "value_assist_dep";
use constant DDValAssistDepUsr => "val_assist_dep_usr";

sub getTypeInfo {
	## METHOD: com.documentum.fc.common.IDfProperties getTypeInfo()
    my $self = shift;
    my $getTypeInfo = JPL::AutoLoader::getmeth('getTypeInfo',[],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getTypeInfo(); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub getAttrInfo {
	## METHOD: com.documentum.fc.common.IDfProperties getAttrInfo(java.lang.String)
    my ($self,$p0) = @_;
    my $getAttrInfo = JPL::AutoLoader::getmeth('getAttrInfo',['java.lang.String'],['com.documentum.fc.common.IDfProperties']);
    my $rv = "";
    eval { $rv = $$self->$getAttrInfo($p0); };
    if (JNI::ExceptionOccurred()) {
        Db::DFC::dfcException();
        return;
    } else {
        bless (\$rv,IDfProperties);
        return \$rv;
    }
}

sub isNewDDInfo {
	## METHOD: boolean isNewDDInfo()
    my $self = shift;
    my $isNewDDInfo = JPL::AutoLoader::getmeth('isNewDDInfo',[],['boolean']);
    my $rv = "";
    eval { $rv = $$self->$isNewDDInfo(); };
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
