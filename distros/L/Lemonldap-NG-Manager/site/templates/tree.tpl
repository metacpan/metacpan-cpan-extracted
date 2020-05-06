    <div id="pleaseWait" ng-show="waiting"><span trspan="waitingForDatas"></span></div>

    <!-- Tree -->
    <aside id="left" class="col-lg-4 col-md-4 col-sm-5 col-xs-12 scrollable " ng-class="{'hidden-xs':!showT}" role="complementary">
      <div class="region region-sidebar-first">
        <section id="block-superfish-1" class="block block-superfish clearfix">
          <div ui-tree data-drag-enabled="false" id="tree-root">
            <div ng-show="data.length==0" class="center">
              <span class="label label-warning" trspan="noData"></span>
            </div>
            <ol ui-tree-nodes="" ng-model="data">
              <li ng-repeat="node in data track by node.id" ui-tree-node ng-include="'nodes_renderer.html'" collapsed="true"></li>
            </ol>
          </div>
        </section>
      </div>
      <div class="hresizer hidden-xs" resizer="vertical" resizer-left="#left" resizer-right="#right"></div>
    </aside>
