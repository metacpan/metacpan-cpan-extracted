Feature: Simple Mojolicious Application Testing
  As a (future) prolific web developer
  I want to test my web application easily
  In order to be even lazier than I currently am
  
  Background:
    Given a mojo test object for the "ExpenseTracker" application
    
  Scenario: Start as logged out
    When I go to "home"
    Then I should see the "Log In" url
    And I should see the "You are not logged in" text
    
  Scenario: Go to login page
    When I go to "login"
    Then I should see the "username" input
    And I should see the "password" input
    And I should see the "login" button

  