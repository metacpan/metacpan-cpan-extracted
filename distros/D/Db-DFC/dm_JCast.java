// ------------------------------------------------------------------ 
// Part of Db::DFC
// (C) 2000-2001 M.S. Roth
// 
// dm_JCast
// ------------------------------------------------------------------ 

import com.documentum.com.*;
import com.documentum.fc.client.*;
import com.documentum.fc.client.qb.*;
import com.documentum.fc.common.*;
import com.documentum.fc.common.session.*;
import com.documentum.operations.*;


public class dm_JCast {

    public IDfDocument castToIDfDocument(Object source) {
    	return (IDfDocument)source;
    }

    public IDfException castToIDfException(Object source) {
    	return (IDfException)source;
    }
    
    public IDfId castToIDfId(Object source) {
    	return (IDfId)source;
    }
    
    public IDfList castToIDfList(Object source) {
    	return (IDfList)source;
    }
    
    public IDfTime castToIDfTime(Object source) {
    	return (IDfTime)source;
    }
    
    public IDfPersistentObject castToIDfPersistentObject(Object source) {
    	return (IDfPersistentObject)source;
    }
    
    public IDfSysObject castToIDfSysObject(Object source) {
    	return (IDfSysObject)source;
    }
    
    public IDfOperationNode castToIDfOperationNode(Object source) {
    	return (IDfOperationNode)source;
    }
    
    public IDfTypedObject castToIDfTypedObject(Object source) {
    	return (IDfTypedObject)source;
    }
    
    public IDfOperation castToIDfOperation(Object source) {
    	return (IDfOperation)source;
    }

       
}    

    