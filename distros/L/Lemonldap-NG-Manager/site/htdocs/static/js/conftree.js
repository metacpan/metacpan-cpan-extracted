function templates(tpl,key) {
    var ind;
    var scalarTemplate = function(r) {
    return {
      "id": tpl+"s/"+(ind++),
      "title": r,
      "get": tpl+"s/"+key+"/"+r
    };
  };
  switch(tpl){
  case 'casAppMetaDataNode':
    return [
   {
      "cnodes" : tpl+"s/"+key+"/"+"casAppMetaDataExportedVars",
      "default" : [
         {
            "data" : "cn",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataExportedVars/cn",
            "title" : "cn",
            "type" : "keyText"
         },
         {
            "data" : "mail",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataExportedVars/mail",
            "title" : "mail",
            "type" : "keyText"
         },
         {
            "data" : "uid",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataExportedVars/uid",
            "title" : "uid",
            "type" : "keyText"
         }
      ],
      "id" : tpl+"s/"+key+"/"+"casAppMetaDataExportedVars",
      "title" : "casAppMetaDataExportedVars",
      "type" : "keyTextContainer"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsService",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsService",
            "title" : "casAppMetaDataOptionsService"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsUserAttribute",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsUserAttribute",
            "title" : "casAppMetaDataOptionsUserAttribute"
         },
         {
            "default" : 1,
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsAllowProxy",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsAllowProxy",
            "title" : "casAppMetaDataOptionsAllowProxy",
            "type" : "bool"
         },
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsLogout",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsLogout",
            "title" : "casAppMetaDataOptionsLogout",
            "type" : "trool"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsAuthnLevel",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsAuthnLevel",
            "title" : "casAppMetaDataOptionsAuthnLevel"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsRule",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsRule",
            "title" : "casAppMetaDataOptionsRule"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsComment",
            "title" : "casAppMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "id" : "casAppMetaDataOptions",
      "title" : "casAppMetaDataOptions",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsDisplayName",
            "id" : tpl+"s/"+key+"/"+"casAppMetaDataOptionsDisplayName",
            "title" : "casAppMetaDataOptionsDisplayName"
         }
      ],
      "id" : "casAppMetaDataOptionsDisplay",
      "title" : "casAppMetaDataOptionsDisplay",
      "type" : "simpleInputContainer"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"casAppMetaDataMacros",
      "default" : [],
      "help" : "exportedvars.html#extend-variables-using-macros-and-groups",
      "id" : tpl+"s/"+key+"/"+"casAppMetaDataMacros",
      "title" : "casAppMetaDataMacros",
      "type" : "keyTextContainer"
   }
]
;
  case 'casSrvMetaDataNode':
    return [
   {
      "cnodes" : tpl+"s/"+key+"/"+"casSrvMetaDataExportedVars",
      "default" : [
         {
            "data" : "cn",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataExportedVars/cn",
            "title" : "cn",
            "type" : "keyText"
         },
         {
            "data" : "mail",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataExportedVars/mail",
            "title" : "mail",
            "type" : "keyText"
         },
         {
            "data" : "uid",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataExportedVars/uid",
            "title" : "uid",
            "type" : "keyText"
         }
      ],
      "id" : tpl+"s/"+key+"/"+"casSrvMetaDataExportedVars",
      "title" : "casSrvMetaDataExportedVars",
      "type" : "keyTextContainer"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsProxiedServices",
      "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsProxiedServices",
      "title" : "casSrvMetaDataOptionsProxiedServices",
      "type" : "keyTextContainer"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsUrl",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsUrl",
            "title" : "casSrvMetaDataOptionsUrl"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsRenew",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsRenew",
            "title" : "casSrvMetaDataOptionsRenew",
            "type" : "bool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsGateway",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsGateway",
            "title" : "casSrvMetaDataOptionsGateway",
            "type" : "bool"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsSamlValidate",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsSamlValidate",
            "title" : "casSrvMetaDataOptionsSamlValidate",
            "type" : "bool"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsComment",
            "title" : "casSrvMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "id" : "casSrvMetaDataOptions",
      "title" : "casSrvMetaDataOptions",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsDisplayName",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsDisplayName",
            "title" : "casSrvMetaDataOptionsDisplayName"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsIcon",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsIcon",
            "title" : "casSrvMetaDataOptionsIcon"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsTooltip",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsTooltip",
            "title" : "casSrvMetaDataOptionsTooltip"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsResolutionRule",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsResolutionRule",
            "title" : "casSrvMetaDataOptionsResolutionRule",
            "type" : "longtext"
         },
         {
            "get" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsSortNumber",
            "id" : tpl+"s/"+key+"/"+"casSrvMetaDataOptionsSortNumber",
            "title" : "casSrvMetaDataOptionsSortNumber",
            "type" : "intOrNull"
         }
      ],
      "id" : "casSrvMetaDataOptionsDisplay",
      "title" : "casSrvMetaDataOptionsDisplay",
      "type" : "simpleInputContainer"
   }
]
;
  case 'oidcOPMetaDataNode':
    return [
   {
      "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataJSON",
      "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataJSON",
      "title" : "oidcOPMetaDataJSON",
      "type" : "file"
   },
   {
      "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataJWKS",
      "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataJWKS",
      "title" : "oidcOPMetaDataJWKS",
      "type" : "file"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars",
      "default" : [
         {
            "data" : "name",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars/cn",
            "title" : "cn",
            "type" : "keyText"
         },
         {
            "data" : "email",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars/mail",
            "title" : "mail",
            "type" : "keyText"
         },
         {
            "data" : "family_name",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars/sn",
            "title" : "sn",
            "type" : "keyText"
         },
         {
            "data" : "sub",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars/uid",
            "title" : "uid",
            "type" : "keyText"
         }
      ],
      "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataExportedVars",
      "title" : "oidcOPMetaDataExportedVars",
      "type" : "keyTextContainer"
   },
   {
      "_nodes" : [
         {
            "_nodes" : [
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsRequirePkce",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsRequirePkce",
                  "title" : "oidcOPMetaDataOptionsRequirePkce",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsStoreIDToken",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsStoreIDToken",
                  "title" : "oidcOPMetaDataOptionsStoreIDToken",
                  "type" : "bool"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsConfigurationURI",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsConfigurationURI",
                  "title" : "oidcOPMetaDataOptionsConfigurationURI"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsJWKSTimeout",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsJWKSTimeout",
                  "title" : "oidcOPMetaDataOptionsJWKSTimeout",
                  "type" : "int"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsClientID",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsClientID",
                  "title" : "oidcOPMetaDataOptionsClientID"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsClientSecret",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsClientSecret",
                  "title" : "oidcOPMetaDataOptionsClientSecret",
                  "type" : "password"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUserAttribute",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUserAttribute",
                  "title" : "oidcOPMetaDataOptionsUserAttribute"
               }
            ],
            "id" : "oidcOPMetaDataOptionsConfiguration",
            "title" : "oidcOPMetaDataOptionsConfiguration",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "default" : "openid profile",
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsScope",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsScope",
                  "title" : "oidcOPMetaDataOptionsScope"
               },
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsDisplay",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsDisplay",
                  "select" : [
                     {
                        "k" : "",
                        "v" : ""
                     },
                     {
                        "k" : "page",
                        "v" : "page"
                     },
                     {
                        "k" : "popup",
                        "v" : "popup"
                     },
                     {
                        "k" : "touch",
                        "v" : "touch"
                     },
                     {
                        "k" : "wap",
                        "v" : "wap"
                     }
                  ],
                  "title" : "oidcOPMetaDataOptionsDisplay",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsPrompt",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsPrompt",
                  "title" : "oidcOPMetaDataOptionsPrompt"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsMaxAge",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsMaxAge",
                  "title" : "oidcOPMetaDataOptionsMaxAge",
                  "type" : "int"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUiLocales",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUiLocales",
                  "title" : "oidcOPMetaDataOptionsUiLocales"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAcrValues",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAcrValues",
                  "title" : "oidcOPMetaDataOptionsAcrValues"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAuthnEndpointAuthMethod",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAuthnEndpointAuthMethod",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "None"
                     },
                     {
                        "k" : "jws",
                        "v" : "Signed JWT"
                     }
                  ],
                  "title" : "oidcOPMetaDataOptionsAuthnEndpointAuthMethod",
                  "type" : "select"
               },
               {
                  "default" : "RS256",
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAuthnEndpointAuthSigAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsAuthnEndpointAuthSigAlg",
                  "select" : [
                     {
                        "k" : "HS256",
                        "v" : "HS256"
                     },
                     {
                        "k" : "HS384",
                        "v" : "HS384"
                     },
                     {
                        "k" : "HS512",
                        "v" : "HS512"
                     },
                     {
                        "k" : "RS256",
                        "v" : "RS256"
                     },
                     {
                        "k" : "RS384",
                        "v" : "RS384"
                     },
                     {
                        "k" : "RS512",
                        "v" : "RS512"
                     },
                     {
                        "k" : "PS256",
                        "v" : "PS256"
                     },
                     {
                        "k" : "PS384",
                        "v" : "PS384"
                     },
                     {
                        "k" : "PS512",
                        "v" : "PS512"
                     },
                     {
                        "k" : "ES256",
                        "v" : "ES256"
                     },
                     {
                        "k" : "ES384",
                        "v" : "ES384"
                     },
                     {
                        "k" : "ES512",
                        "v" : "ES512"
                     },
                     {
                        "k" : "EdDSA",
                        "v" : "EdDSA"
                     }
                  ],
                  "title" : "oidcOPMetaDataOptionsAuthnEndpointAuthSigAlg",
                  "type" : "select"
               },
               {
                  "default" : "client_secret_post",
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsTokenEndpointAuthMethod",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsTokenEndpointAuthMethod",
                  "select" : [
                     {
                        "k" : "client_secret_post",
                        "v" : "client_secret_post"
                     },
                     {
                        "k" : "client_secret_basic",
                        "v" : "client_secret_basic"
                     },
                     {
                        "k" : "client_secret_jwt",
                        "v" : "client_secret_jwt"
                     },
                     {
                        "k" : "private_key_jwt",
                        "v" : "private_key_jwt"
                     }
                  ],
                  "title" : "oidcOPMetaDataOptionsTokenEndpointAuthMethod",
                  "type" : "select"
               },
               {
                  "default" : 1,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsCheckJWTSignature",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsCheckJWTSignature",
                  "title" : "oidcOPMetaDataOptionsCheckJWTSignature",
                  "type" : "bool"
               },
               {
                  "default" : 30,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsIDTokenMaxAge",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsIDTokenMaxAge",
                  "title" : "oidcOPMetaDataOptionsIDTokenMaxAge",
                  "type" : "int"
               },
               {
                  "default" : 1,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUseNonce",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUseNonce",
                  "title" : "oidcOPMetaDataOptionsUseNonce",
                  "type" : "bool"
               },
               {
                  "default" : "userinfo",
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUserinfoSource",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsUserinfoSource",
                  "select" : [
                     {
                        "k" : "userinfo",
                        "v" : "Userinfo endpoint"
                     },
                     {
                        "k" : "id_token",
                        "v" : "ID Token"
                     },
                     {
                        "k" : "access_token",
                        "v" : "Access Token"
                     }
                  ],
                  "title" : "oidcOPMetaDataOptionsUserinfoSource",
                  "type" : "select"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsNoJwtHeader",
                  "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsNoJwtHeader",
                  "title" : "oidcOPMetaDataOptionsNoJwtHeader",
                  "type" : "bool"
               }
            ],
            "id" : "oidcOPMetaDataOptionsProtocol",
            "title" : "oidcOPMetaDataOptionsProtocol",
            "type" : "simpleInputContainer"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsComment",
            "title" : "oidcOPMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "help" : "authopenidconnect.html#options",
      "id" : "oidcOPMetaDataOptions",
      "title" : "oidcOPMetaDataOptions"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsDisplayName",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsDisplayName",
            "title" : "oidcOPMetaDataOptionsDisplayName"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsIcon",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsIcon",
            "title" : "oidcOPMetaDataOptionsIcon"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsTooltip",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsTooltip",
            "title" : "oidcOPMetaDataOptionsTooltip"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsResolutionRule",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsResolutionRule",
            "title" : "oidcOPMetaDataOptionsResolutionRule",
            "type" : "longtext"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsSortNumber",
            "id" : tpl+"s/"+key+"/"+"oidcOPMetaDataOptionsSortNumber",
            "title" : "oidcOPMetaDataOptionsSortNumber",
            "type" : "intOrNull"
         }
      ],
      "help" : "authopenidconnect.html#display",
      "id" : "oidcOPMetaDataOptionsDisplayParams",
      "title" : "oidcOPMetaDataOptionsDisplayParams",
      "type" : "simpleInputContainer"
   }
]
;
  case 'oidcRPMetaDataNode':
    return [
   {
      "_nodes" : [
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsPublic",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsPublic",
            "title" : "oidcRPMetaDataOptionsPublic",
            "type" : "bool"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsClientID",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsClientID",
            "title" : "oidcRPMetaDataOptionsClientID"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsClientSecret",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsClientSecret",
            "title" : "oidcRPMetaDataOptionsClientSecret",
            "type" : "password"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRedirectUris",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRedirectUris",
            "title" : "oidcRPMetaDataOptionsRedirectUris"
         }
      ],
      "help" : "idpopenidconnect.html#basic-options",
      "id" : "oidcRPMetaDataOptionsBasic",
      "title" : "oidcRPMetaDataOptionsBasic",
      "type" : "simpleInputContainer"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"oidcRPMetaDataExportedVars",
      "default" : [
         {
            "data" : [
               "mail",
               "string",
               "auto"
            ],
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataExportedVars/email",
            "title" : "email",
            "type" : "oidcAttribute"
         },
         {
            "data" : [
               "cn",
               "string",
               "auto"
            ],
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataExportedVars/name",
            "title" : "name",
            "type" : "oidcAttribute"
         },
         {
            "data" : [
               "uid",
               "string",
               "auto"
            ],
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataExportedVars/preferred_username",
            "title" : "preferred_username",
            "type" : "oidcAttribute"
         }
      ],
      "help" : "idpopenidconnect.html#exported-attributes",
      "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataExportedVars",
      "title" : "oidcRPMetaDataExportedVars",
      "type" : "oidcAttributeContainer"
   },
   {
      "_nodes" : [
         {
            "_nodes" : [
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsBypassConsent",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsBypassConsent",
                  "title" : "oidcRPMetaDataOptionsBypassConsent",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenForceClaims",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenForceClaims",
                  "title" : "oidcRPMetaDataOptionsIDTokenForceClaims",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenJWT",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenJWT",
                  "title" : "oidcRPMetaDataOptionsAccessTokenJWT",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenClaims",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenClaims",
                  "title" : "oidcRPMetaDataOptionsAccessTokenClaims",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRefreshToken",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRefreshToken",
                  "title" : "oidcRPMetaDataOptionsRefreshToken",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsNoJwtHeader",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsNoJwtHeader",
                  "title" : "oidcRPMetaDataOptionsNoJwtHeader",
                  "type" : "bool"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserIDAttr",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserIDAttr",
                  "title" : "oidcRPMetaDataOptionsUserIDAttr"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAdditionalAudiences",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAdditionalAudiences",
                  "title" : "oidcRPMetaDataOptionsAdditionalAudiences"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsTokenXAuthorizedRP",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsTokenXAuthorizedRP",
                  "title" : "oidcRPMetaDataOptionsTokenXAuthorizedRP"
               }
            ],
            "id" : "oidcRPMetaDataOptionsAdvanced",
            "title" : "oidcRPMetaDataOptionsAdvanced",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "cnodes" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsExtraClaims",
                  "default" : [],
                  "help" : "idpopenidconnect.html#oidcextraclaims",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsExtraClaims",
                  "title" : "oidcRPMetaDataOptionsExtraClaims",
                  "type" : "keyTextContainer"
               },
               {
                  "cnodes" : tpl+"s/"+key+"/"+"oidcRPMetaDataScopeRules",
                  "default" : [],
                  "help" : "idpopenidconnect.html#scope-rules",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataScopeRules",
                  "title" : "oidcRPMetaDataScopeRules",
                  "type" : "keyTextContainer"
               }
            ],
            "id" : "oidcRPMetaDataOptionsScopes",
            "title" : "oidcRPMetaDataOptionsScopes"
         },
         {
            "_nodes" : [
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRequirePKCE",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRequirePKCE",
                  "title" : "oidcRPMetaDataOptionsRequirePKCE",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRefreshTokenRotation",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRefreshTokenRotation",
                  "title" : "oidcRPMetaDataOptionsRefreshTokenRotation",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowOffline",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowOffline",
                  "title" : "oidcRPMetaDataOptionsAllowOffline",
                  "type" : "bool"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowNativeSso",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowNativeSso",
                  "title" : "oidcRPMetaDataOptionsAllowNativeSso",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowPasswordGrant",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowPasswordGrant",
                  "title" : "oidcRPMetaDataOptionsAllowPasswordGrant",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowClientCredentialsGrant",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAllowClientCredentialsGrant",
                  "title" : "oidcRPMetaDataOptionsAllowClientCredentialsGrant",
                  "type" : "bool"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRequestUris",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRequestUris",
                  "title" : "oidcRPMetaDataOptionsRequestUris"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnLevel",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnLevel",
                  "title" : "oidcRPMetaDataOptionsAuthnLevel"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRule",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsRule",
                  "title" : "oidcRPMetaDataOptionsRule"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthMethod",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthMethod",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "Any"
                     },
                     {
                        "k" : "client_secret_post",
                        "v" : "client_secret_post"
                     },
                     {
                        "k" : "client_secret_basic",
                        "v" : "client_secret_basic"
                     },
                     {
                        "k" : "client_secret_jwt",
                        "v" : "client_secret_jwt"
                     },
                     {
                        "k" : "private_key_jwt",
                        "v" : "private_key_jwt"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsAuthMethod",
                  "type" : "select"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthRequiredForAuthorize",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthRequiredForAuthorize",
                  "title" : "oidcRPMetaDataOptionsAuthRequiredForAuthorize",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnRequireState",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnRequireState",
                  "title" : "oidcRPMetaDataOptionsAuthnRequireState",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnRequireNonce",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthnRequireNonce",
                  "title" : "oidcRPMetaDataOptionsAuthnRequireNonce",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserinfoRequireHeaderToken",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserinfoRequireHeaderToken",
                  "title" : "oidcRPMetaDataOptionsUserinfoRequireHeaderToken",
                  "type" : "bool"
               }
            ],
            "id" : "security",
            "title" : "security",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "default" : "RS256",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenSignAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenSignAlg",
                  "select" : [
                     {
                        "k" : "none",
                        "v" : "None"
                     },
                     {
                        "k" : "HS256",
                        "v" : "HS256"
                     },
                     {
                        "k" : "HS384",
                        "v" : "HS384"
                     },
                     {
                        "k" : "HS512",
                        "v" : "HS512"
                     },
                     {
                        "k" : "RS256",
                        "v" : "RS256"
                     },
                     {
                        "k" : "RS384",
                        "v" : "RS384"
                     },
                     {
                        "k" : "RS512",
                        "v" : "RS512"
                     },
                     {
                        "k" : "PS256",
                        "v" : "PS256"
                     },
                     {
                        "k" : "PS384",
                        "v" : "PS384"
                     },
                     {
                        "k" : "PS512",
                        "v" : "PS512"
                     },
                     {
                        "k" : "ES256",
                        "v" : "ES256"
                     },
                     {
                        "k" : "ES384",
                        "v" : "ES384"
                     },
                     {
                        "k" : "ES512",
                        "v" : "ES512"
                     },
                     {
                        "k" : "EdDSA",
                        "v" : "EdDSA"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsIDTokenSignAlg",
                  "type" : "select"
               },
               {
                  "default" : "RS256",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenSignAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenSignAlg",
                  "select" : [
                     {
                        "k" : "HS256",
                        "v" : "HS256"
                     },
                     {
                        "k" : "HS384",
                        "v" : "HS384"
                     },
                     {
                        "k" : "HS512",
                        "v" : "HS512"
                     },
                     {
                        "k" : "RS256",
                        "v" : "RS256"
                     },
                     {
                        "k" : "RS384",
                        "v" : "RS384"
                     },
                     {
                        "k" : "RS512",
                        "v" : "RS512"
                     },
                     {
                        "k" : "PS256",
                        "v" : "PS256"
                     },
                     {
                        "k" : "PS384",
                        "v" : "PS384"
                     },
                     {
                        "k" : "PS512",
                        "v" : "PS512"
                     },
                     {
                        "k" : "ES256",
                        "v" : "ES256"
                     },
                     {
                        "k" : "ES384",
                        "v" : "ES384"
                     },
                     {
                        "k" : "ES512",
                        "v" : "ES512"
                     },
                     {
                        "k" : "EdDSA",
                        "v" : "EdDSA"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsAccessTokenSignAlg",
                  "type" : "select"
               },
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoSignAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoSignAlg",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "JSON"
                     },
                     {
                        "k" : "none",
                        "v" : "JWT/None"
                     },
                     {
                        "k" : "HS256",
                        "v" : "JWT/HS256"
                     },
                     {
                        "k" : "HS384",
                        "v" : "JWT/HS384"
                     },
                     {
                        "k" : "HS512",
                        "v" : "JWT/HS512"
                     },
                     {
                        "k" : "RS256",
                        "v" : "JWT/RS256"
                     },
                     {
                        "k" : "RS384",
                        "v" : "JWT/RS384"
                     },
                     {
                        "k" : "RS512",
                        "v" : "JWT/RS512"
                     },
                     {
                        "k" : "PS256",
                        "v" : "JWT/PS256"
                     },
                     {
                        "k" : "PS384",
                        "v" : "JWT/PS384"
                     },
                     {
                        "k" : "PS512",
                        "v" : "JWT/PS512"
                     },
                     {
                        "k" : "ES256",
                        "v" : "JWT/ES256"
                     },
                     {
                        "k" : "ES384",
                        "v" : "JWT/ES384"
                     },
                     {
                        "k" : "ES512",
                        "v" : "JWT/ES512"
                     },
                     {
                        "k" : "EdDSA",
                        "v" : "JWT/EdDSA"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsUserInfoSignAlg",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "None"
                     },
                     {
                        "k" : "RSA-OAEP",
                        "v" : "RSA-OAEP"
                     },
                     {
                        "k" : "RSA-OAEP-256",
                        "v" : "RSA-OAEP-256"
                     },
                     {
                        "k" : "RSA1_5",
                        "v" : "RSA1_5"
                     },
                     {
                        "k" : "ECDH-ES",
                        "v" : "ECDH-ES"
                     },
                     {
                        "k" : "ECDH-ES+A128KW",
                        "v" : "ECDH-ES+A128KW"
                     },
                     {
                        "k" : "ECDH-ES+A192KW",
                        "v" : "ECDH-ES+A192KW"
                     },
                     {
                        "k" : "ECDH-ES+A256KW",
                        "v" : "ECDH-ES+A256KW"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg",
                  "type" : "select"
               },
               {
                  "default" : "A256GCM",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenEncContentEncAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenEncContentEncAlg",
                  "select" : [
                     {
                        "k" : "A256CBC-HS512",
                        "v" : "A256CBC-HS512"
                     },
                     {
                        "k" : "A256GCM",
                        "v" : "A256GCM"
                     },
                     {
                        "k" : "A192CBC-HS384",
                        "v" : "A192CBC-HS384"
                     },
                     {
                        "k" : "A192GCM",
                        "v" : "A192GCM"
                     },
                     {
                        "k" : "A128CBC-HS256",
                        "v" : "A128CBC-HS256"
                     },
                     {
                        "k" : "A128GCM",
                        "v" : "A128GCM"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsAccessTokenEncContentEncAlg",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "None"
                     },
                     {
                        "k" : "RSA-OAEP",
                        "v" : "RSA-OAEP"
                     },
                     {
                        "k" : "RSA-OAEP-256",
                        "v" : "RSA-OAEP-256"
                     },
                     {
                        "k" : "RSA1_5",
                        "v" : "RSA1_5"
                     },
                     {
                        "k" : "ECDH-ES",
                        "v" : "ECDH-ES"
                     },
                     {
                        "k" : "ECDH-ES+A128KW",
                        "v" : "ECDH-ES+A128KW"
                     },
                     {
                        "k" : "ECDH-ES+A192KW",
                        "v" : "ECDH-ES+A192KW"
                     },
                     {
                        "k" : "ECDH-ES+A256KW",
                        "v" : "ECDH-ES+A256KW"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg",
                  "type" : "select"
               },
               {
                  "default" : "A256GCM",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIdTokenEncContentEncAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIdTokenEncContentEncAlg",
                  "select" : [
                     {
                        "k" : "A256CBC-HS512",
                        "v" : "A256CBC-HS512"
                     },
                     {
                        "k" : "A256GCM",
                        "v" : "A256GCM"
                     },
                     {
                        "k" : "A192CBC-HS384",
                        "v" : "A192CBC-HS384"
                     },
                     {
                        "k" : "A192GCM",
                        "v" : "A192GCM"
                     },
                     {
                        "k" : "A128CBC-HS256",
                        "v" : "A128CBC-HS256"
                     },
                     {
                        "k" : "A128GCM",
                        "v" : "A128GCM"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsIdTokenEncContentEncAlg",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "None"
                     },
                     {
                        "k" : "RSA-OAEP",
                        "v" : "RSA-OAEP"
                     },
                     {
                        "k" : "RSA-OAEP-256",
                        "v" : "RSA-OAEP-256"
                     },
                     {
                        "k" : "RSA1_5",
                        "v" : "RSA1_5"
                     },
                     {
                        "k" : "ECDH-ES",
                        "v" : "ECDH-ES"
                     },
                     {
                        "k" : "ECDH-ES+A128KW",
                        "v" : "ECDH-ES+A128KW"
                     },
                     {
                        "k" : "ECDH-ES+A192KW",
                        "v" : "ECDH-ES+A192KW"
                     },
                     {
                        "k" : "ECDH-ES+A256KW",
                        "v" : "ECDH-ES+A256KW"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg",
                  "type" : "select"
               },
               {
                  "default" : "A256GCM",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoEncContentEncAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsUserInfoEncContentEncAlg",
                  "select" : [
                     {
                        "k" : "A256CBC-HS512",
                        "v" : "A256CBC-HS512"
                     },
                     {
                        "k" : "A256GCM",
                        "v" : "A256GCM"
                     },
                     {
                        "k" : "A192CBC-HS384",
                        "v" : "A192CBC-HS384"
                     },
                     {
                        "k" : "A192GCM",
                        "v" : "A192GCM"
                     },
                     {
                        "k" : "A128CBC-HS256",
                        "v" : "A128CBC-HS256"
                     },
                     {
                        "k" : "A128GCM",
                        "v" : "A128GCM"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsUserInfoEncContentEncAlg",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutEncKeyMgtAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutEncKeyMgtAlg",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "None"
                     },
                     {
                        "k" : "RSA-OAEP",
                        "v" : "RSA-OAEP"
                     },
                     {
                        "k" : "RSA-OAEP-256",
                        "v" : "RSA-OAEP-256"
                     },
                     {
                        "k" : "RSA1_5",
                        "v" : "RSA1_5"
                     },
                     {
                        "k" : "ECDH-ES",
                        "v" : "ECDH-ES"
                     },
                     {
                        "k" : "ECDH-ES+A128KW",
                        "v" : "ECDH-ES+A128KW"
                     },
                     {
                        "k" : "ECDH-ES+A192KW",
                        "v" : "ECDH-ES+A192KW"
                     },
                     {
                        "k" : "ECDH-ES+A256KW",
                        "v" : "ECDH-ES+A256KW"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsLogoutEncKeyMgtAlg",
                  "type" : "select"
               },
               {
                  "default" : "A256GCM",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutEncContentEncAlg",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutEncContentEncAlg",
                  "select" : [
                     {
                        "k" : "A256CBC-HS512",
                        "v" : "A256CBC-HS512"
                     },
                     {
                        "k" : "A256GCM",
                        "v" : "A256GCM"
                     },
                     {
                        "k" : "A192CBC-HS384",
                        "v" : "A192CBC-HS384"
                     },
                     {
                        "k" : "A192GCM",
                        "v" : "A192GCM"
                     },
                     {
                        "k" : "A128CBC-HS256",
                        "v" : "A128CBC-HS256"
                     },
                     {
                        "k" : "A128GCM",
                        "v" : "A128GCM"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsLogoutEncContentEncAlg",
                  "type" : "select"
               }
            ],
            "id" : "algorithms",
            "title" : "algorithms",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsJwksUri",
                  "help" : "idpopenidconnect.html",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsJwksUri",
                  "title" : "oidcRPMetaDataOptionsJwksUri"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsJwks",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsJwks",
                  "title" : "oidcRPMetaDataOptionsJwks",
                  "type" : "file"
               }
            ],
            "id" : "keys",
            "title" : "keys"
         },
         {
            "_nodes" : [
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthorizationCodeExpiration",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAuthorizationCodeExpiration",
                  "title" : "oidcRPMetaDataOptionsAuthorizationCodeExpiration",
                  "type" : "intOrNull"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenExpiration",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIDTokenExpiration",
                  "title" : "oidcRPMetaDataOptionsIDTokenExpiration",
                  "type" : "intOrNull"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenExpiration",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsAccessTokenExpiration",
                  "title" : "oidcRPMetaDataOptionsAccessTokenExpiration",
                  "type" : "intOrNull"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsOfflineSessionExpiration",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsOfflineSessionExpiration",
                  "title" : "oidcRPMetaDataOptionsOfflineSessionExpiration",
                  "type" : "intOrNull"
               }
            ],
            "id" : "oidcRPMetaDataOptionsTimeouts",
            "title" : "oidcRPMetaDataOptionsTimeouts",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutBypassConfirm",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutBypassConfirm",
                  "title" : "oidcRPMetaDataOptionsLogoutBypassConfirm",
                  "type" : "bool"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutSessionRequired",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutSessionRequired",
                  "title" : "oidcRPMetaDataOptionsLogoutSessionRequired",
                  "type" : "bool"
               },
               {
                  "default" : "front",
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutType",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutType",
                  "select" : [
                     {
                        "k" : "front",
                        "v" : "Front Channel"
                     },
                     {
                        "k" : "back",
                        "v" : "Back Channel"
                     }
                  ],
                  "title" : "oidcRPMetaDataOptionsLogoutType",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutUrl",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsLogoutUrl",
                  "title" : "oidcRPMetaDataOptionsLogoutUrl"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsPostLogoutRedirectUris",
                  "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsPostLogoutRedirectUris",
                  "title" : "oidcRPMetaDataOptionsPostLogoutRedirectUris"
               }
            ],
            "id" : "logout",
            "title" : "logout",
            "type" : "simpleInputContainer"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsComment",
            "title" : "oidcRPMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "help" : "idpopenidconnect.html#options",
      "id" : "oidcRPMetaDataOptions",
      "title" : "oidcRPMetaDataOptions"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"oidcRPMetaDataMacros",
      "default" : [],
      "help" : "exportedvars.html#extend-variables-using-macros-and-groups",
      "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataMacros",
      "title" : "oidcRPMetaDataMacros",
      "type" : "keyTextContainer"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsDisplayName",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsDisplayName",
            "title" : "oidcRPMetaDataOptionsDisplayName"
         },
         {
            "get" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIcon",
            "id" : tpl+"s/"+key+"/"+"oidcRPMetaDataOptionsIcon",
            "title" : "oidcRPMetaDataOptionsIcon"
         }
      ],
      "help" : "idpopenidconnect.html#display",
      "id" : "oidcRPMetaDataOptionsDisplay",
      "title" : "oidcRPMetaDataOptionsDisplay",
      "type" : "simpleInputContainer"
   }
]
;
  case 'samlIDPMetaDataNode':
    return [
   {
      "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataXML",
      "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataXML",
      "title" : "samlIDPMetaDataXML",
      "type" : "file"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"samlIDPMetaDataExportedAttributes",
      "default" : [],
      "help" : "authsaml.html#exported-attributes",
      "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataExportedAttributes",
      "title" : "samlIDPMetaDataExportedAttributes",
      "type" : "samlAttributeContainer"
   },
   {
      "_nodes" : [
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsAdaptSessionUtime",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsAdaptSessionUtime",
            "title" : "samlIDPMetaDataOptionsAdaptSessionUtime",
            "type" : "bool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsForceUTF8",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsForceUTF8",
            "title" : "samlIDPMetaDataOptionsForceUTF8",
            "type" : "bool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsStoreSAMLToken",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsStoreSAMLToken",
            "title" : "samlIDPMetaDataOptionsStoreSAMLToken",
            "type" : "bool"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsUserAttribute",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsUserAttribute",
            "title" : "samlIDPMetaDataOptionsUserAttribute"
         }
      ],
      "help" : "authsaml.html#session",
      "id" : "samlIDPMetaDataOptionsSession",
      "title" : "samlIDPMetaDataOptionsSession",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignatureMethod",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignatureMethod",
            "select" : [
               {
                  "k" : "",
                  "v" : "default"
               },
               {
                  "k" : "RSA_SHA1",
                  "v" : "RSA SHA1"
               },
               {
                  "k" : "RSA_SHA256",
                  "v" : "RSA SHA256"
               },
               {
                  "k" : "RSA_SHA384",
                  "v" : "RSA SHA384"
               },
               {
                  "k" : "RSA_SHA512",
                  "v" : "RSA SHA512"
               }
            ],
            "title" : "samlIDPMetaDataOptionsSignatureMethod",
            "type" : "select"
         },
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignSSOMessage",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignSSOMessage",
            "title" : "samlIDPMetaDataOptionsSignSSOMessage",
            "type" : "trool"
         },
         {
            "default" : 1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckSSOMessageSignature",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckSSOMessageSignature",
            "title" : "samlIDPMetaDataOptionsCheckSSOMessageSignature",
            "type" : "bool"
         },
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignSLOMessage",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSignSLOMessage",
            "title" : "samlIDPMetaDataOptionsSignSLOMessage",
            "type" : "trool"
         },
         {
            "default" : 1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckSLOMessageSignature",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckSLOMessageSignature",
            "title" : "samlIDPMetaDataOptionsCheckSLOMessageSignature",
            "type" : "bool"
         }
      ],
      "help" : "authsaml.html#signature",
      "id" : "samlIDPMetaDataOptionsSignature",
      "title" : "samlIDPMetaDataOptionsSignature",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSSOBinding",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSSOBinding",
            "select" : [
               {
                  "k" : "",
                  "v" : ""
               },
               {
                  "k" : "http-post",
                  "v" : "POST"
               },
               {
                  "k" : "http-redirect",
                  "v" : "Redirect"
               },
               {
                  "k" : "artifact-get",
                  "v" : "Artifact GET"
               }
            ],
            "title" : "samlIDPMetaDataOptionsSSOBinding",
            "type" : "select"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSLOBinding",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSLOBinding",
            "select" : [
               {
                  "k" : "",
                  "v" : ""
               },
               {
                  "k" : "http-post",
                  "v" : "POST"
               },
               {
                  "k" : "http-redirect",
                  "v" : "Redirect"
               },
               {
                  "k" : "http-soap",
                  "v" : "SOAP"
               }
            ],
            "title" : "samlIDPMetaDataOptionsSLOBinding",
            "type" : "select"
         }
      ],
      "help" : "authsaml.html#binding",
      "id" : "samlIDPMetaDataOptionsBinding",
      "title" : "samlIDPMetaDataOptionsBinding",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "default" : "none",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsEncryptionMode",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsEncryptionMode",
            "select" : [
               {
                  "k" : "none",
                  "v" : "None"
               },
               {
                  "k" : "nameid",
                  "v" : "Name ID"
               },
               {
                  "k" : "assertion",
                  "v" : "Assertion"
               }
            ],
            "title" : "samlIDPMetaDataOptionsEncryptionMode",
            "type" : "select"
         },
         {
            "default" : 1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckTime",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckTime",
            "title" : "samlIDPMetaDataOptionsCheckTime",
            "type" : "bool"
         },
         {
            "default" : 1,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckAudience",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsCheckAudience",
            "title" : "samlIDPMetaDataOptionsCheckAudience",
            "type" : "bool"
         }
      ],
      "help" : "authsaml.html#security",
      "id" : "samlIDPMetaDataOptionsSecurity",
      "title" : "samlIDPMetaDataOptionsSecurity",
      "type" : "simpleInputContainer"
   },
   {
      "_nodes" : [
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsNameIDFormat",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsNameIDFormat",
            "select" : [
               {
                  "k" : "",
                  "v" : ""
               },
               {
                  "k" : "unspecified",
                  "v" : "Unspecified"
               },
               {
                  "k" : "email",
                  "v" : "Email"
               },
               {
                  "k" : "x509",
                  "v" : "X509 certificate"
               },
               {
                  "k" : "windows",
                  "v" : "Windows"
               },
               {
                  "k" : "kerberos",
                  "v" : "Kerberos"
               },
               {
                  "k" : "entity",
                  "v" : "Entity"
               },
               {
                  "k" : "persistent",
                  "v" : "Persistent"
               },
               {
                  "k" : "transient",
                  "v" : "Transient"
               },
               {
                  "k" : "encrypted",
                  "v" : "Encrypted"
               }
            ],
            "title" : "samlIDPMetaDataOptionsNameIDFormat",
            "type" : "select"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsForceAuthn",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsForceAuthn",
            "title" : "samlIDPMetaDataOptionsForceAuthn",
            "type" : "bool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsIsPassive",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsIsPassive",
            "title" : "samlIDPMetaDataOptionsIsPassive",
            "type" : "bool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsAllowLoginFromIDP",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsAllowLoginFromIDP",
            "title" : "samlIDPMetaDataOptionsAllowLoginFromIDP",
            "type" : "bool"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsRequestedAuthnContext",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsRequestedAuthnContext",
            "select" : [
               {
                  "k" : "",
                  "v" : ""
               },
               {
                  "k" : "kerberos",
                  "v" : "Kerberos"
               },
               {
                  "k" : "password-protected-transport",
                  "v" : "Password protected transport"
               },
               {
                  "k" : "password",
                  "v" : "Password"
               },
               {
                  "k" : "tls-client",
                  "v" : "TLS client certificate"
               }
            ],
            "title" : "samlIDPMetaDataOptionsRequestedAuthnContext",
            "type" : "select"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsRelayStateURL",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsRelayStateURL",
            "title" : "samlIDPMetaDataOptionsRelayStateURL",
            "type" : "bool"
         },
         {
            "_nodes" : [
               {
                  "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsFederationEntityID",
                  "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsFederationEntityID",
                  "title" : "samlIDPMetaDataOptionsFederationEntityID"
               }
            ],
            "id" : "samlIDPMetaDataOptionsFederation",
            "title" : "samlIDPMetaDataOptionsFederation",
            "type" : "simpleInputContainer"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsComment",
            "title" : "samlIDPMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "help" : "authsaml.html#options",
      "id" : "samlIDPMetaDataOptions",
      "title" : "samlIDPMetaDataOptions"
   },
   {
      "_nodes" : [
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsDisplayName",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsDisplayName",
            "title" : "samlIDPMetaDataOptionsDisplayName"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsIcon",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsIcon",
            "title" : "samlIDPMetaDataOptionsIcon"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsTooltip",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsTooltip",
            "title" : "samlIDPMetaDataOptionsTooltip"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsResolutionRule",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsResolutionRule",
            "title" : "samlIDPMetaDataOptionsResolutionRule",
            "type" : "longtext"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSortNumber",
            "id" : tpl+"s/"+key+"/"+"samlIDPMetaDataOptionsSortNumber",
            "title" : "samlIDPMetaDataOptionsSortNumber",
            "type" : "intOrNull"
         }
      ],
      "help" : "authsaml.html#display",
      "id" : "samlIDPMetaDataOptionsDisplay",
      "title" : "samlIDPMetaDataOptionsDisplay",
      "type" : "simpleInputContainer"
   }
]
;
  case 'samlSPMetaDataNode':
    return [
   {
      "get" : tpl+"s/"+key+"/"+"samlSPMetaDataXML",
      "id" : tpl+"s/"+key+"/"+"samlSPMetaDataXML",
      "title" : "samlSPMetaDataXML",
      "type" : "file"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"samlSPMetaDataExportedAttributes",
      "default" : [],
      "help" : "idpsaml.html#exported-attributes",
      "id" : tpl+"s/"+key+"/"+"samlSPMetaDataExportedAttributes",
      "title" : "samlSPMetaDataExportedAttributes",
      "type" : "samlAttributeContainer"
   },
   {
      "_nodes" : [
         {
            "_nodes" : [
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNameIDFormat",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNameIDFormat",
                  "select" : [
                     {
                        "k" : "",
                        "v" : ""
                     },
                     {
                        "k" : "unspecified",
                        "v" : "Unspecified"
                     },
                     {
                        "k" : "email",
                        "v" : "Email"
                     },
                     {
                        "k" : "x509",
                        "v" : "X509 certificate"
                     },
                     {
                        "k" : "windows",
                        "v" : "Windows"
                     },
                     {
                        "k" : "kerberos",
                        "v" : "Kerberos"
                     },
                     {
                        "k" : "entity",
                        "v" : "Entity"
                     },
                     {
                        "k" : "persistent",
                        "v" : "Persistent"
                     },
                     {
                        "k" : "transient",
                        "v" : "Transient"
                     },
                     {
                        "k" : "encrypted",
                        "v" : "Encrypted"
                     }
                  ],
                  "title" : "samlSPMetaDataOptionsNameIDFormat",
                  "type" : "select"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNameIDSessionKey",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNameIDSessionKey",
                  "title" : "samlSPMetaDataOptionsNameIDSessionKey"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsOneTimeUse",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsOneTimeUse",
                  "title" : "samlSPMetaDataOptionsOneTimeUse",
                  "type" : "bool"
               },
               {
                  "default" : 72000,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSessionNotOnOrAfterTimeout",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSessionNotOnOrAfterTimeout",
                  "title" : "samlSPMetaDataOptionsSessionNotOnOrAfterTimeout",
                  "type" : "int"
               },
               {
                  "default" : 72000,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNotOnOrAfterTimeout",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsNotOnOrAfterTimeout",
                  "title" : "samlSPMetaDataOptionsNotOnOrAfterTimeout",
                  "type" : "int"
               },
               {
                  "default" : 1,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsForceUTF8",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsForceUTF8",
                  "title" : "samlSPMetaDataOptionsForceUTF8",
                  "type" : "bool"
               }
            ],
            "id" : "samlSPMetaDataOptionsAuthnResponse",
            "title" : "samlSPMetaDataOptionsAuthnResponse",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignatureMethod",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignatureMethod",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "default"
                     },
                     {
                        "k" : "RSA_SHA1",
                        "v" : "RSA SHA1"
                     },
                     {
                        "k" : "RSA_SHA256",
                        "v" : "RSA SHA256"
                     },
                     {
                        "k" : "RSA_SHA384",
                        "v" : "RSA SHA384"
                     },
                     {
                        "k" : "RSA_SHA512",
                        "v" : "RSA SHA512"
                     }
                  ],
                  "title" : "samlSPMetaDataOptionsSignatureMethod",
                  "type" : "select"
               },
               {
                  "default" : -1,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignSSOMessage",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignSSOMessage",
                  "title" : "samlSPMetaDataOptionsSignSSOMessage",
                  "type" : "trool"
               },
               {
                  "default" : 1,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsCheckSSOMessageSignature",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsCheckSSOMessageSignature",
                  "title" : "samlSPMetaDataOptionsCheckSSOMessageSignature",
                  "type" : "bool"
               },
               {
                  "default" : -1,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignSLOMessage",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsSignSLOMessage",
                  "title" : "samlSPMetaDataOptionsSignSLOMessage",
                  "type" : "trool"
               },
               {
                  "default" : 1,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsCheckSLOMessageSignature",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsCheckSLOMessageSignature",
                  "title" : "samlSPMetaDataOptionsCheckSLOMessageSignature",
                  "type" : "bool"
               }
            ],
            "id" : "samlSPMetaDataOptionsSignature",
            "title" : "samlSPMetaDataOptionsSignature",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "default" : "none",
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsEncryptionMode",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsEncryptionMode",
                  "select" : [
                     {
                        "k" : "none",
                        "v" : "None"
                     },
                     {
                        "k" : "nameid",
                        "v" : "Name ID"
                     },
                     {
                        "k" : "assertion",
                        "v" : "Assertion"
                     }
                  ],
                  "title" : "samlSPMetaDataOptionsEncryptionMode",
                  "type" : "select"
               },
               {
                  "default" : 0,
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsEnableIDPInitiatedURL",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsEnableIDPInitiatedURL",
                  "title" : "samlSPMetaDataOptionsEnableIDPInitiatedURL",
                  "type" : "bool"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsAuthnLevel",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsAuthnLevel",
                  "title" : "samlSPMetaDataOptionsAuthnLevel"
               },
               {
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsRule",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsRule",
                  "title" : "samlSPMetaDataOptionsRule"
               }
            ],
            "id" : "samlSPMetaDataOptionsSecurity",
            "title" : "samlSPMetaDataOptionsSecurity",
            "type" : "simpleInputContainer"
         },
         {
            "_nodes" : [
               {
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationEntityID",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationEntityID",
                  "title" : "samlSPMetaDataOptionsFederationEntityID"
               },
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationOptionalAttributes",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationOptionalAttributes",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "keep"
                     },
                     {
                        "k" : "ignore",
                        "v" : "ignore"
                     }
                  ],
                  "title" : "samlSPMetaDataOptionsFederationOptionalAttributes",
                  "type" : "select"
               },
               {
                  "default" : "",
                  "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationRequiredAttributes",
                  "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsFederationRequiredAttributes",
                  "select" : [
                     {
                        "k" : "",
                        "v" : "keep"
                     },
                     {
                        "k" : "optional",
                        "v" : "makeoptional"
                     },
                     {
                        "k" : "ignore",
                        "v" : "ignore"
                     }
                  ],
                  "title" : "samlSPMetaDataOptionsFederationRequiredAttributes",
                  "type" : "select"
               }
            ],
            "id" : "samlSPMetaDataOptionsFederation",
            "title" : "samlSPMetaDataOptionsFederation",
            "type" : "simpleInputContainer"
         },
         {
            "get" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsComment",
            "id" : tpl+"s/"+key+"/"+"samlSPMetaDataOptionsComment",
            "title" : "samlSPMetaDataOptionsComment",
            "type" : "longtext"
         }
      ],
      "help" : "idpsaml.html#options",
      "id" : "samlSPMetaDataOptions",
      "title" : "samlSPMetaDataOptions"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"samlSPMetaDataMacros",
      "default" : [],
      "help" : "exportedvars.html#extend-variables-using-macros-and-groups",
      "id" : tpl+"s/"+key+"/"+"samlSPMetaDataMacros",
      "title" : "samlSPMetaDataMacros",
      "type" : "keyTextContainer"
   }
]
;
  case 'virtualHost':
    return [
   {
      "cnodes" : tpl+"s/"+key+"/"+"locationRules",
      "default" : [
         {
            "data" : "deny",
            "id" : tpl+"s/"+key+"/"+"locationRules/default",
            "re" : "default",
            "title" : "default",
            "type" : "rule"
         }
      ],
      "help" : "writingrulesand_headers.html#rules",
      "id" : tpl+"s/"+key+"/"+"locationRules",
      "title" : "locationRules",
      "type" : "ruleContainer"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"exportedHeaders",
      "help" : "writingrulesand_headers.html#headers",
      "id" : tpl+"s/"+key+"/"+"exportedHeaders",
      "title" : "exportedHeaders",
      "type" : "keyTextContainer"
   },
   {
      "cnodes" : tpl+"s/"+key+"/"+"post",
      "help" : "formreplay.html",
      "id" : tpl+"s/"+key+"/"+"post",
      "title" : "post",
      "type" : "postContainer"
   },
   {
      "_nodes" : [
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"vhostPort",
            "id" : tpl+"s/"+key+"/"+"vhostPort",
            "title" : "vhostPort",
            "type" : "int"
         },
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"vhostHttps",
            "id" : tpl+"s/"+key+"/"+"vhostHttps",
            "title" : "vhostHttps",
            "type" : "trool"
         },
         {
            "default" : 0,
            "get" : tpl+"s/"+key+"/"+"vhostMaintenance",
            "id" : tpl+"s/"+key+"/"+"vhostMaintenance",
            "title" : "vhostMaintenance",
            "type" : "bool"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"vhostAliases",
            "id" : tpl+"s/"+key+"/"+"vhostAliases",
            "title" : "vhostAliases"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"vhostAccessToTrace",
            "id" : tpl+"s/"+key+"/"+"vhostAccessToTrace",
            "title" : "vhostAccessToTrace"
         },
         {
            "get" : tpl+"s/"+key+"/"+"vhostAuthnLevel",
            "id" : tpl+"s/"+key+"/"+"vhostAuthnLevel",
            "title" : "vhostAuthnLevel",
            "type" : "intOrNull"
         },
         {
            "default" : "Main",
            "get" : tpl+"s/"+key+"/"+"vhostType",
            "id" : tpl+"s/"+key+"/"+"vhostType",
            "select" : [
               {
                  "k" : "AuthBasic",
                  "v" : "AuthBasic"
               },
               {
                  "k" : "CDA",
                  "v" : "CDA"
               },
               {
                  "k" : "DevOps",
                  "v" : "DevOps"
               },
               {
                  "k" : "DevOpsST",
                  "v" : "DevOpsST"
               },
               {
                  "k" : "DevOpsCDA",
                  "v" : "DevOpsCDA"
               },
               {
                  "k" : "Main",
                  "v" : "Main"
               },
               {
                  "k" : "OAuth2",
                  "v" : "OAuth2"
               },
               {
                  "k" : "SecureToken",
                  "v" : "SecureToken"
               },
               {
                  "k" : "ServiceToken",
                  "v" : "ServiceToken"
               },
               {
                  "k" : "ZimbraPreAuth",
                  "v" : "ZimbraPreAuth"
               }
            ],
            "title" : "vhostType",
            "type" : "select"
         },
         {
            "get" : tpl+"s/"+key+"/"+"vhostDevOpsRulesUrl",
            "id" : tpl+"s/"+key+"/"+"vhostDevOpsRulesUrl",
            "title" : "vhostDevOpsRulesUrl"
         },
         {
            "default" : -1,
            "get" : tpl+"s/"+key+"/"+"vhostServiceTokenTTL",
            "id" : tpl+"s/"+key+"/"+"vhostServiceTokenTTL",
            "title" : "vhostServiceTokenTTL",
            "type" : "int"
         },
         {
            "default" : "",
            "get" : tpl+"s/"+key+"/"+"vhostComment",
            "id" : tpl+"s/"+key+"/"+"vhostComment",
            "title" : "vhostComment",
            "type" : "longtext"
         }
      ],
      "help" : "configvhost.html#options",
      "id" : "vhostOptions",
      "title" : "vhostOptions",
      "type" : "simpleInputContainer"
   }
]
;
  default:
    return [];
  }
}

function setScopeVars(scope) {
  scope.portal = scope.data[0]._nodes[0]._nodes[0];
  scope.getKey(scope.portal);
  scope.domain = scope.data[0]._nodes[4]._nodes[1];
  scope.getKey(scope.domain);
}