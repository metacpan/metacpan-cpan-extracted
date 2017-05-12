# What is it ?

This project was started by [**9h37 SAS**](http://9h37.fr)

*lemonldap-ng-cli* is a command line tool to configure **LemonLDAP::NG** from the
command line. Make you able to deploy your web application faster and easier.

# Installation

***To be written***

# How to use

Set/get variables in the configuration:

```
lemonldap-ng-cli set <variable> <value>
lemonldap-ng-cli unset <variable>
lemonldap-ng-cli get <variable>
```

Define macros:

```
lemonldap-ng-cli set-macro <macro name> <perl expression>
lemonldap-ng-cli unset-macro <macro name>
lemonldap-ng-cli get-macro <macro name>
```

Modify application list:

```
lemonldap-ng-cli apps-set-cat <cat id> <cat name>
lemonldap-ng-cli apps-get-cat <cat id>

lemonldap-ng-cli apps-add <app id> <cat id>
lemonldap-ng-cli apps-set-uri <app id> <app uri>
lemonldap-ng-cli apps-set-name <app id> <app name>
lemonldap-ng-cli apps-set-desc <app id> <app description>
lemonldap-ng-cli apps-set-logo <app id> <logo>
lemonldap-ng-cli apps-set-display <app id> <app display>

lemonldap-ng-cli apps-get <app id>
lemonldap-ng-cli apps-rm <app id>
```

Manage rules:

```
lemonldap-ng-cli rules-set <virtual host> <expr> <rule>
lemonldap-ng-cli rules-unset <virtual host> <expr>
lemonldap-ng-cli rules-get <virtual host>
```

Manage exported variables:

```
lemonldap-ng-cli export-var <key> <value>
lemonldap-ng-cli unexport-var <key>
lemonldap-ng-cli get-exported-vars
```

Manage exported headers:

```
lemonldap-ng-cli export-header <virtual host> <HTTP header> <perl expression>
lemonldap-ng-cli unexport-header <virtual host> <HTTP header>
lemonldap-ng-cli get-exported-headers <virtual host>
```

Manage virtual hosts:

```
lemonldap-ng-cli vhost-add <virtual host uri>
lemonldap-ng-cli vhost-del <virtual host>
lemonldap-ng-cli vhost-set-port <virtual host> <port>
lemonldap-ng-cli vhost-set-https <virtual host> <value>
lemonldap-ng-cli vhost-set-maintenance  <virtual host> <value>
lemonldap-ng-cli vhost-list
```

Global Storage:

```
lemonldap-ng-cli global-storage
lemonldap-ng-cli global-storage-set-dir <path>
lemonldap-ng-cli global-storage-set-lockdir <path>
```

Reload URLs:

```
lemonldap-ng-cli reload-urls
lemonldap-ng-cli reload-url-add <vhost> <url>
lemonldap-ng-cli reload-url-del <vhost>
```
