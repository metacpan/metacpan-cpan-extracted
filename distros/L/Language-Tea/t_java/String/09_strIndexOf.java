//package pt.v1.tea.testapp;

class MainProgram {

    public static void main(String[] args) {
        try {
            String a = "there's a disturbance on da force luke";
            String b = "x";
            System.out.println((a.indexOf(b)));
        } catch(Exception e) {
            System.out.println(e.getMessage());
        }
    }

}
