# Lemonldap::NG::Manager forms

This files contains the form used to expose configuration attributes. The form
is chosen by looking at the *type* property of the current data.

This property is defined in `Lemonldap::NG::Manager::Build::Attributes` package.
By default, it is set to *text*.

`Lemonldap::NG::Manager::Build::Attributes` is compiled into JSON/JS files by
`jsongenerator.pl`script.

## 1. Form file architecture

Form files must be called `<type>.json` where *<type>* is the declared type of
configuration property to display.

Form files must contain only HTML that will be included in the manager DOM
*(in `#form` div)*. It **must** consist of two blocks:

* a `<div class="panel panel-default">` div that contains the form,
* a `<script type="text/menu">` script that defines which item to display
  in context menu.

Basic example:

    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title">{{translate(currentNode)}}</h3>
      </div>
      <div class="panel-body">
        <div class="input-group">
          <label class="input-group-addon" for="textinput" trspan="value"></label>
          <input id="textinput" class="form-control" ng-model="currentNode.data"/>
        </div>
      </div>
    </div>
    <script type="text/menu">
    [{
      "title": "cancel"
    }]
    </script>

## 2. Form main div

Based on bootstrap CSS, the main div part may look like:

If configuration item name is read-only:

    <div class="panel panel-default">
      <div class="panel-heading">
        <h3 class="panel-title">{{translate(currentNode)}}</h3>
      </div>
      <div class="panel-body">
      __ FORM INPUTS __
      </div>
    </div>

If configuration item name may be modified:

    <div class="panel panel-default">
      <div class="panel-heading"> <!-- optional -->
        <h3 class="panel-title" trspan="OptionalTitle"></h3>
      </div>
      <div class="panel-body">
      __ FORM INPUTS __
      </div>
    </div>

> Note that keywords to translate must be set in all `languages/*.json` files.

### 2.1. AngularJS bindings

Some AngularJS variables are available :

* `currentNode`: the data subnode corresponding to the selected tree item
* `currentScope`: the AngularJS scope corresponding to the selected tree item

You can simply used them as follow:

    <input class="form-control" ng-model="currentNode.data"/>

## 3. Script part

Form div **must** define which item menu to display. It is done via the script part
of the file:

Empty context menu:

    <script type="text/menu">
    []
    </script>

Else:

    <script type="text/menu">
    [
      {<menu item1>},
      {<menu item2>},
      {<menu item3>}
    ]
    </script>

### 3.1. Menu item

#### 3.1.1. Simple case

Menu item is a javascript object with at least the key `title`.

    <script type="text/menu">
    [
      { "title": "cancel" }
    ]
    </script>

In this case, the item will be displayed using the translation of *cancel*. It
will launch the function `$scope.cancel()` declared in AngularJS controller
*(`js/manager.js` file)* without any argument: functions in the controller can
access to controller properties and methods.

#### 3.1.2. Dropdown item

You can have sub items simply using `buttons` key which must then be an array
of menu items.

    <script type="text/menu">
    [{
      "title": "textToTranslate",
      "buttons": [
        { "title": "cancel" },
        { "other": "item" }
      ]
    }]
    </script>

#### 3.1.3. Specify function to use

    <script type="text/menu">
    [{
      "title": "addVirtualHost",
      "action": "addVhost"
    }]
    </script>

Same as below except that it will launch `$scope.addVhost()`.

##### Tips

You can access to the parent using this:

* `currentScope.$parentNodeScope` for the parent scope
* `currentScope.$parentNodeScope.$modelValue` for the parent node

#### 3.1.5 Icons

    <script type="text/menu">
    [{
      "title": "addVirtualHost",
      "action": "addVhost",
      "icon": "plus-sign",
    }]
    </script>

The field `icon` can be set to define the Bootstrap glyphicon to use.

## 4. Modal window

You can use a modal window to display a choice (look at forms/portalSkin.html
for a complete example):

    <button class="btn btn-info" ng-click="showModal('portalSkinChoice.html')">

A modal window will be displayed using `portalSkinChoice.html` template. This
template must be declared in the file:

    <script type="text/ng-template" id="portalSkinChoice.html">
      <div class="modal-header">
        <h3 class="modal-title" trspan="chooseSkin"></h3>
      </div>
      <div class="modal-body">
        <div class="btn-group">
          <button class="btn" ng-repeat="b in currentNode.select" ng-click="ok(currentNode.data=b.k)">
            {{b.v}}
          </button>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-primary" ng-click="ok()" trspan="ok"></button>
        <button class="btn btn-warning" ng-click="cancel()" trspan="cancel"></button>
      </div>
    </script>

